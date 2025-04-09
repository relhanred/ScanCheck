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
    private let apiKey = "YOUR_OPENAI_API_KEY"
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
        
        // Construire la requête pour l'API ChatGPT
        let requestBody: [String: Any] = [
            "model": "gpt-4-vision-preview",
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
            
            do {
                // Parser la réponse de l'API
                let responseJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                guard let choices = responseJSON?["choices"] as? [[String: Any]],
                      let firstChoice = choices.first,
                      let message = firstChoice["message"] as? [String: Any],
                      let content = message["content"] as? String else {
                    throw NSError(domain: "CheckAnalyzerService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Format de réponse invalide"])
                }
                
                // Extraire le JSON de la réponse (en supprimant les balises de code s'il y en a)
                let jsonContent = content.replacingOccurrences(of: "```json", with: "")
                                        .replacingOccurrences(of: "```", with: "")
                                        .trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Décoder la réponse JSON en objet Swift
                let jsonData = jsonContent.data(using: .utf8)!
                let analysisResponse = try JSONDecoder().decode(CheckAnalysisResponse.self, from: jsonData)
                
                DispatchQueue.main.async {
                    completion(.success(analysisResponse))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}
