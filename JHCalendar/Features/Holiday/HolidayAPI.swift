import Foundation

struct HolidayResponse: Decodable {
    let response: Body
    
    struct Body: Decodable {
        let header: Header
        let body: Items
    }
    struct Header: Decodable {
        let resultCode: String
        let resultMsg: String
    }
    struct Items: Decodable {
        let items: ItemList
    }
    struct ItemList: Decodable {
        let item: [HolidayDTO]
    }
}

struct HolidayDTO: Decodable {
    let dateName: String
    let isHoliday: String
    let locdate: Int
}

enum HolidayAPIError: Error {
    case missingApiKey
    case http(status: Int)
    case decoding(Error)
}

func fetchHoliday(year: Int) async throws -> [HolidayDTO] {
    let allowed = CharacterSet.urlQueryAllowed.subtracting(.init(charactersIn: "+/="))
    guard let encodedKey = Secrets.holidayApiKey.addingPercentEncoding(withAllowedCharacters: allowed) else {
        throw HolidayAPIError.missingApiKey
    }
    var comp = URLComponents(string: "https://apis.data.go.kr/B090041/openapi/service/SpcdeInfoService/getRestDeInfo")!
    comp.percentEncodedQueryItems = [
        URLQueryItem(name: "solYear", value: "\(year)"),
        URLQueryItem(name: "numOfRows", value: "100"),
        URLQueryItem(name: "_type", value: "json"),
        URLQueryItem(name: "ServiceKey", value: encodedKey)
    ]
    let url = comp.url!
    let (data, response) = try await URLSession.shared.data(from: url)
    
    guard let http = response as? HTTPURLResponse else {
        throw HolidayAPIError.http(status: -1)
    }
    guard (200..<300).contains(http.statusCode) else {
        throw HolidayAPIError.http(status: http.statusCode)
    }
    
    return try JSONDecoder().decode(HolidayResponse.self, from: data).response.body.items.item
}
