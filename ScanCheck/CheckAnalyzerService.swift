import Foundation
import UIKit

// Structures pour le décodage des réponses JSON
struct CheckAnalysisResponse: Codable {
    let status: String
    let amount_eur: String?
    let pay_to: String?
    let bank_name: String?
    let cheque_number: String?
    let date: String?
    let location: String?
    let message: String?
}

class CheckAnalyzerService {
    // Remplacez cette clé API par votre propre clé d'API OpenAI
    private let apiKey = APIConfig.openAIKey
    private let apiURL = "https://api.openai.com/v1/chat/completions"
    
    func analyzeCheckImage(_ image: UIImage, completion: @escaping (Result<CheckAnalysisResponse, Error>) -> Void) {
        // Convertir l'image en base64
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(.failure(NSError(domain: "CheckAnalyzerService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Échec de conversion de l'image"])))
            return
        }
        
        let base64Image = imageData.base64EncodedString()
        
        // Construire le prompt pour l'API
        let prompt = """
        Tu es un expert en traitement d'images et en lecture de documents manuscrits et imprimés. Je vais t'envoyer l'image d'un chèque bancaire français. Ton rôle est d'extraire de manière fiable les informations suivantes depuis le chèque, même si certaines données sont manuscrites. Si l'image ne correspond pas à un chèque ou si elle est illisible, retourne un message d'erreur avec le statut "error" et le message "Image non reconnue comme un chèque". Sinon, donne-moi uniquement la réponse au format JSON avec exactement les clés suivantes, même si certaines valeurs ne sont pas lisibles (dans ce cas, mets null) : { "status": "success", "amount_eur": "", "pay_to": "", "bank_name": "", "cheque_number": "", "date": "", "location": "" } Détails : - "status" : indique si l'extraction a réussi, "success" si le chèque est reconnu, "error" si l'image n'est pas un chèque ou ne peut pas être traité. - "amount_eur" : le montant en euros, au format numérique avec deux décimales (ex : 123.45) - "pay_to" : le nom ou l'intitulé de la personne ou entité à qui le chèque est adressé - "bank_name" : le nom de la banque émettrice du chèque - "cheque_number" : les 7 chiffres du numéro du chèque (souvent en bas à droite ou dans la ligne MICR) - "date" : la date du chèque au format JJ/MM/AAAA - "location" : le lieu de rédaction du chèque (souvent indiqué près de la date) Si l'image ne correspond pas à un chèque ou si elle est mal interprétée, retourne uniquement ceci : { "status": "error", "message": "Image non reconnue comme un chèque" } Ne fais aucun autre commentaire, retourne seulement le JSON.
        """
        
        // Construire la requête pour l'API ChatGPT en utilisant le nouveau format
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",  // Utilisation du modèle mentionné dans l'exemple JavaScript
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 300
        ]
        
        // Créer la requête HTTP
        var request = URLRequest(url: URL(string: apiURL)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        // Effectuer la requête
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "CheckAnalyzerService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Aucune donnée reçue"])))
                }
                return
            }
            
            // Afficher la réponse brute pour le débogage
            if let responseString = String(data: data, encoding: .utf8) {
                print("Réponse brute de l'API: \(responseString)")
            }
            
            do {
                // Parser la réponse de l'API
                guard let responseJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    throw NSError(domain: "CheckAnalyzerService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Échec de parsing du JSON"])
                }
                
                // Vérifier si nous avons une erreur d'API
                if let error = responseJSON["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    throw NSError(domain: "CheckAnalyzerService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Erreur API: \(message)"])
                }
                
                // Extraire le contenu du message de la réponse
                guard let choices = responseJSON["choices"] as? [[String: Any]],
                      !choices.isEmpty,
                      let firstChoice = choices.first,
                      let message = firstChoice["message"] as? [String: Any],
                      let content = message["content"] as? String else {
                    throw NSError(domain: "CheckAnalyzerService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Format de réponse invalide"])
                }
                
                print("Contenu extrait: \(content)")
                
                // Extraire le JSON de la réponse (en supprimant les balises de code s'il y en a)
                let jsonContent = self.extractJSONFromContent(content)
                print("JSON extrait: \(jsonContent)")
                
                // Tenter de décoder la réponse JSON en objet Swift
                let jsonData = jsonContent.data(using: .utf8)!
                do {
                    let analysisResponse = try JSONDecoder().decode(CheckAnalysisResponse.self, from: jsonData)
                    DispatchQueue.main.async {
                        completion(.success(analysisResponse))
                    }
                } catch let decodingError {
                    print("Erreur de décodage JSON: \(decodingError)")
                    
                    // Si nous ne pouvons pas décoder directement, créer une réponse d'erreur par défaut
                    let fallbackResponse = CheckAnalysisResponse(
                        status: "error",
                        amount_eur: nil,
                        pay_to: nil,
                        bank_name: nil,
                        cheque_number: nil,
                        date: nil,
                        location: nil,
                        message: "Impossible d'analyser l'image. Veuillez vérifier que l'image est bien celle d'un chèque et réessayer."
                    )
                    
                    DispatchQueue.main.async {
                        completion(.success(fallbackResponse))
                    }
                }
            } catch let parsingError {
                print("Erreur de parsing: \(parsingError)")
                DispatchQueue.main.async {
                    completion(.failure(parsingError))
                }
            }
        }.resume()
    }
    
    // Helper pour extraire le JSON d'une chaîne de caractères pouvant contenir des balises Markdown
    private func extractJSONFromContent(_ content: String) -> String {
        // Supprimer les balises de code markdown
        let withoutCodeBlocks = content.replacingOccurrences(of: "```json", with: "")
                                      .replacingOccurrences(of: "```", with: "")
                                      .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Rechercher un objet JSON entre accolades
        if let startRange = withoutCodeBlocks.range(of: "{"),
           let endRange = withoutCodeBlocks.range(of: "}", options: .backwards) {
            let startIndex = startRange.lowerBound
            let endIndex = endRange.upperBound
            
            if startIndex < endIndex {
                return String(withoutCodeBlocks[startIndex..<endIndex])
            }
        }
        
        // Si nous ne trouvons pas un JSON valide, créer un JSON d'erreur par défaut
        return """
        {
            "status": "error",
            "message": "Format de réponse non reconnu"
        }
        """
    }
}
