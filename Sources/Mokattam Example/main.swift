import Foundation
import Mokattam

let mokattam = Mokattam()
mokattam.showCursor = false

let label = mokattam.append(element: TextLabel("How awesome is this?"))
let selection = mokattam.append(element: Select(choices: [
        ("Pretty cool.", 0),
        ("Awesome", 1),
        ("Uneblievable?!?!", 2),
        ("Not that awesome", 3)
    ])).read()
let username = mokattam.append(element: TextInput(label: "Username: ")).read()
let password = mokattam.append(element: TextInput(label: "Password: ", echo: false)).read()

mokattam.close()

print(selection)
print(username)
print(password)
