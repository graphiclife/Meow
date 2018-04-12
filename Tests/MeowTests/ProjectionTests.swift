import XCTest

@testable import Meow

class ProjectionCat : Model, CustomDebugStringConvertible {
  var _id = ObjectId()

  var name: String
  var age: Int?
  var favoriteFood: String?

  init(name: String, age: Int? = nil, favoriteFood: String? = nil) {
    self.name = name
    self.age = age
    self.favoriteFood = favoriteFood
  }

  var debugDescription: String {
    var result = ""

    result.append("Name: \(name)")

    if let age = age {
      result.append(", age: \(age)")
    }

    if let favoriteFood = favoriteFood {
      result.append(", favorite food: \(favoriteFood)")
    }

    return result
  }
}

class ProjectionTests: XCTestCase {
  override func setUp() {
    do {
      try Meow.init("mongodb://localhost/MeowProjectionSample")

      try ProjectionCat.collection.remove()

      let cat = ProjectionCat(name: "Henkie", age: 8, favoriteFood: "Pasta")
      try cat.save()
    } catch {
      XCTFail("\(error)")
    }
  }

  func testProjection() {
    do {
      if let foundCat = try ProjectionCat.findOne("name" == "Henkie", projecting: [ "name": true ]) {
        XCTAssertEqual(foundCat.name, "Henkie")
      } else {
        XCTFail("no cat found")
      }

      if let foundCat = try ProjectionCat.findOne("name" == "Henkie", projecting: [ "name": true, "age": true ]) {
        XCTAssertEqual(foundCat.name, "Henkie")
        XCTAssertEqual(foundCat.age, 8)
      } else {
        XCTFail("no cat found")
      }

      if let foundCat = try ProjectionCat.findOne("name" == "Henkie", projecting: [ "favoriteFood": false ]) {
        XCTAssertEqual(foundCat.name, "Henkie")
        XCTAssertEqual(foundCat.age, 8)
        XCTAssertEqual(foundCat.favoriteFood, nil)
      } else {
        XCTFail("no cat found")
      }

      if let foundCat = try ProjectionCat.findOne("name" == "Henkie", projecting: [ "name": true, "age": true, "favoriteFood": true ]) {
        XCTAssertEqual(foundCat.name, "Henkie")
        XCTAssertEqual(foundCat.age, 8)
        XCTAssertEqual(foundCat.favoriteFood, "Pasta")
      } else {
        XCTFail("no cat found")
      }
    } catch {
      XCTFail("\(error)")
    }

    XCTAssertEqual(true, true)
  }

  static var allTests = [
      ("testProjection", testProjection),
  ]
}
