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
        Tu es un expert en traitement d’images et OCR, spécialisé dans la lecture de chèques bancaires français et police CMC7, y compris les parties manuscrites et imprimées.

        Je vais t’envoyer une image. Tu dois en extraire de manière fiable les informations d’un chèque, même si certaines sont écrites à la main.

        Si l’image ne correspond pas à un chèque ou est floue/illisible, retourne uniquement ce JSON :
        {
          "status": "error",
          "message": "Image non reconnue comme un chèque"
        }

        Sinon, retourne **exactement** ce JSON structuré :
        {
          "status": "success",
          "amount_eur": "", 
          "pay_to": "", 
          "bank_name": "", 
          "cheque_number": "", 
          "date": "", 
          "location": ""
        }

        ### Détail des champs à extraire :

        - **amount_eur** : Montant du chèque, en euros, au format numérique avec deux décimales (exemple : 120.50). Priorité au montant en chiffres s’il est présent.

        - **pay_to** : Nom de la personne ou entité à qui le chèque est adressé. Ce nom suit souvent l’expression “à l’ordre de” ou “à”.

        - **bank_name** : Nom de la banque, généralement imprimé en haut à gauche ou en bas du chèque.

        - **cheque_number** : Numéro de chèque (7 chiffres), extrait **uniquement** depuis le **premier groupe de chiffres à gauche dans la bande CMC7** (ligne MICR en bas du chèque). Ignore tous les autres groupes et les symboles.

        - **date** : Date de rédaction du chèque, au format JJ/MM/AAAA. Elle se trouve souvent manuscrite en haut à droite ou à droite du chèque. Complète-la intelligemment si elle est partiellement lisible.

        - **location** : Lieu de rédaction du chèque, généralement une **ville en France**, écrit en haut à droite ou juste au-dessus de la date.

        ### Contraintes importantes :

        - Concentre toi bien sur la lecture du numéro de chèque, n'hésite pas à faire plusieurs scan et à comparer les résultats les plus probables.
        - Le numéro de chèque est toujours un groupe de **7 chiffres consécutifs**, situé **à gauche** de la bande CMC7 (ligne magnétique en bas du chèque). **Ne pas tenir compte des autres groupes à droite.**
        - Si une information est manquante, partiellement illisible ou absente, remplace-la par `null`.

        Ta réponse doit être **exclusivement** le JSON final, sans aucun commentaire ou explication.


        """
        
        // Construire la requête pour l'API ChatGPT en utilisant le nouveau format
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
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
