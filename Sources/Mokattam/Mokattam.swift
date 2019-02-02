import Foundation
import Darwin

public protocol MokattamElement {
    var y: Int {get set}
    var id: Int {get set}
    var height: Int {get}
    func display()
    var mokattam: Mokattam? {get set}
}
public protocol Printable {
    var count: Int {get}
    var content: String {get}
    var rendered: String {get}
}
extension String: Printable {
    public var content: String {
        return self
    }
    public var rendered: String {
        return self
    }
}
public class TextInput: MokattamElement {
    public var y: Int = -1
    public var id: Int = -1
    
    public var height: Int = 1
    var label: Printable
    var content: String {
        return left + right
    }
    var left: String = ""
    var right: String = ""
    var cursor: Printable
    var editing = false
    var echo: Bool
    
    public init(content: String = "", cursor: Printable = "|", label: Printable = "", echo: Bool = true) {
        self.label = label
        self.left = content
        self.cursor = cursor
        self.echo = echo
    }
    public func display() {
        var str = ""
        
        str += label.rendered
        if echo {
            str += left
        }
        if editing {
            str += cursor.rendered
        }
        if echo {
            str += right
        }
        print(str)
    }
    public func read()-> String{
        guard let mokattam = mokattam else{
            return ""
        }
        editing = true
        mokattam.update(id: id)
        
        mokattam.rawMode()
        defer {
            editing = false
            mokattam.reset()
            mokattam.update(id: id)
        }
        var finishedReading = false
        while !finishedReading {
            let key = mokattam.waitForKeypress()
            switch key {
            case .enter:
                finishedReading = true
            case .printable(let character):
                left += character
                mokattam.update(id: id)
            case .abort:
                finishedReading = true
            case .arrow(let direction):
                switch direction {
                case .left:
                    if let lastLetter = left.last {
                        right = String(lastLetter) + right
                        left = String(left.dropLast())
                    }
                case .right:
                    if let firstLetter = right.first {
                        right = String(right.dropFirst())
                        left.append(firstLetter)
                    }
                case .up:
                    break
                case .down:
                    break
                }
                mokattam.update(id: id)
            case .delete:
                left = String(left.dropLast())
                mokattam.update(id: id)
            }
        }
        return content
    }
    
    public var mokattam: Mokattam?
}
public class ProgressBar: MokattamElement {
    public var y: Int = -1
    public var id: Int = -1
    public var height: Int = 1
    
    var width: Int
    var start: Printable
    var end: Printable
    var filled: Printable
    var notFilled: Printable
    
    public var progress: Float {
        didSet {
            mokattam?.update(id: id)
        }
    }
    
    public init(width: Int = 30, start: Printable = "[", end: Printable = "]", filled: Printable = "#", notFilled: Printable = " ", progress: Float = 0.0) {
        self.width = width
        self.start = start
        self.end = end
        self.filled = filled
        self.notFilled = notFilled
        self.progress = progress
    }
    
    public func display() {
        var str = ""
        str += start.rendered
        
        let contentWidth = width - start.count - end.count
        let numFilled = Int(round(Float(contentWidth) * progress))
        
        str += String(repeating: filled.rendered, count: numFilled / filled.count)
        str += String(repeating: notFilled.rendered, count: (contentWidth - numFilled) / filled.count)
        
        str += end.rendered
        print(str)
    }
    
    public var mokattam: Mokattam?
}
public class TextLabel: MokattamElement {
    public var y: Int = -1
    public var text: String {
        didSet {
            mokattam?.update(id: id)
        }
    }
    public var id: Int = -1
    public var height: Int = 1
    public func display() {
        print(text)
    }
    weak public var mokattam: Mokattam?
    public init(_ text: String) {
        self.text = text
    }
}
public enum TextAlignment {
    case left
    case right
}
public class Column<T> {
    let name: Printable
    let formatter: (T)->Printable
    let alignment: TextAlignment
    public init(name: Printable, formatter: @escaping (T)->Printable, alignment: TextAlignment = .left) {
        self.name = name
        self.formatter = formatter
        self.alignment = alignment
    }
}
public enum TableStyle {
    case `default`
    case simple(drawHeader: Bool)
    
    var drawHeader: Bool {
        switch self {
        case .default:
            return true
        case .simple(let drawHeader):
            return drawHeader
        }
    }
}
public class Table<T>: MokattamElement {
    public var y: Int = -1
    public var id: Int = -1
    public var data: [T]  = []{
        didSet {
            mokattam?.update(id: id)
        }
    }
    public var height: Int {
        return data.count + (style.drawHeader ? 1 : 0)
    }
    
    
    public var mokattam: Mokattam?
    
    let columns: [Column<T>]
    let style: TableStyle
    public init(columns: [Column<T>], style: TableStyle = .default) {
        self.columns = columns
        self.style = style
    }
    public func display() {
        var text: [[Printable]] = []
        var maxWidth: [Int] = [Int](repeating: 0, count: columns.count)
        for object in data {
            var row: [Printable] = []
            for (index, column) in columns.enumerated() {
                let str = column.formatter(object)
                if str.count > maxWidth[index] {
                    maxWidth[index] = str.count
                }
                row.append(str)
            }
            text.append(row)
        }
        
        if style.drawHeader {
            var str = ""
            for (i, column) in columns.enumerated() {
                let lengthOfContent = column.name.count
                if lengthOfContent > maxWidth[i] {
                    maxWidth[i] = lengthOfContent
                }
                let desiredLength = maxWidth[i]
                let content = column.name.content
                
                let filler = String(repeating: " ", count: desiredLength - lengthOfContent)
                let cell: String
                switch column.alignment {
                case .left:
                    cell = content + filler
                case .right:
                    cell = filler + content
                }
                str += cell
                str += " "
            }
            
            print(str)
        }
        for row in text {
            var str = ""
            for (i,element) in row.enumerated() {
                let column = columns[i]
                let desiredLength = maxWidth[i]
                let lengthOfContent = element.count
                let filler = String(repeating: " ", count: desiredLength - lengthOfContent)
                let cell: String
                let content = element.rendered
                switch column.alignment {
                case .left:
                    cell = content + filler
                case .right:
                    cell = filler + content
                }
                str += cell
                
                str += " "
            }
            print(str)
        }
    }
}
public class Select<T>: MokattamElement {
    public var y: Int = -1
    public var id: Int = -1
    
    public var height: Int {
        return choices.count
    }
    
    var allowMultipleSelections: Bool
    var choices: [Printable]
    var res: [T]
    var selection: [Bool]
    var index: Int
    
    var notSelected: Printable
    var hover: Printable
    var selected: Printable
    var hoverSelected: Printable
    
    public init(choices: [(Printable, T)], allowMultipleSelections: Bool = true, index: Int = 0, notSelected: Printable = "[ ]", hover: Printable = "> <", selected: Printable = "[X]", hoverSelected: Printable = ">X<") {
        self.allowMultipleSelections = allowMultipleSelections
        
        self.choices = choices.map({$0.0})
        self.res = choices.map({$0.1})
        self.selection = [Bool](repeating: false, count: choices.count)
        
        self.index = index
        self.notSelected = notSelected
        self.hover = hover
        self.selected = selected
        self.hoverSelected = hoverSelected
    }
    
    public func display() {
        guard let mokattam = mokattam else {
            return
        }
        for (i, choice) in choices.enumerated() {
            var s = ""
            switch (selection[i], i == index) {
            case (false, false):
                s += notSelected.rendered
            case (false, true):
                s += hover.rendered
            case (true, false):
                s += selected.rendered
            case (true, true):
                s += hoverSelected.rendered
            }
            s += " "
            s += choice.rendered
            mokattam.moveToBeginning()
            mokattam.clearLine()
            print(s)
        }
    }
    public func read()-> [T]{
        guard let mokattam = mokattam else {
            return []
        }
        defer {
            mokattam.reset()
        }
        mokattam.update(id: id)
        mokattam.rawMode()
        repeat {
            let keypress = mokattam.waitForKeypress()
            switch keypress {
            case .enter:
                var result: [T] = []
                for (i, element) in selection.enumerated() {
                    if element {
                        result.append(res[i])
                    }
                }
                return result
            case .printable(let string):
                if string == " " {
                    selection[index] = !selection[index]
                    mokattam.update(id: id)
                }
            case .abort:
                return []
            case .arrow(let direction):
                switch direction {
                case .left:
                    break
                case .right:
                    break
                case .up:
                    index -= 1
                    index %= choices.count
                    mokattam.update(id: id)
                case .down:
                    index += 1
                    index %= choices.count
                    mokattam.update(id: id)
                }
            case .delete:
                break
            }
        }while true
    }
    
    public var mokattam: Mokattam?
}

public class Mokattam {
    var elements: [MokattamElement]
    var old: termios = termios()
    public init() {
        elements = []
        tcgetattr( STDIN_FILENO, &old);
    }
    public func reset() {
        tcsetattr(STDIN_FILENO, TCSANOW, &old)
    }
    public func close() {
        tcsetattr(STDIN_FILENO, TCSANOW, &old)
        if !showCursor {
            showCursor = true
        }
        print("\u{001B}[?25h")
    }
    public func rawMode() {
        var new = old
        cfmakeraw(&new)
        new.c_lflag &= ~UInt(ECHO);
        tcsetattr(STDIN_FILENO, TCSANOW, &new)
    }
    deinit {
        
    }
    var cursorY: Int = 0
    public func append<T>(element e: T) -> T where T: MokattamElement {
        var element = e
        element.mokattam = self
        element.id = elements.count
        element.y = cursorY
        
        elements.append(element)
        
        update(id: element.id, initial: true)
        return element
    }
    func write(code: String) {
        print("\u{001B}[\(code)", separator: "", terminator: "")
    }
    func clearLine() {
        write(code: "2K")
    }
    func moveToBeginning() {
        write(code: "100D")
    }
    func moveUp(_ num: Int) {
        guard num > 0 else {
            return
        }
        write(code: "\(num)A")
    }
    func moveDown(_ num: Int) {
        guard num > 0 else {
            return
        }
        write(code: "\(num)B")
    }
    public var showCursor: Bool = true{
        didSet {
            if showCursor {
                write(code: "?25h")
            }else{
                write(code: "?25l")
            }
        }
    }
    func update(id: Int, initial: Bool = false) {
        let element = elements[id]
        
        if !initial {
            moveUp(cursorY - element.y)
            clearLine()
            moveToBeginning()
        }else{
            moveToBeginning()
        }
        elements[id].display()
        
        if elements.count > (id + 1) {
            let next = elements[id + 1]
            if next.y != element.y + element.height {
                var y = element.y + element.height
                for i in (id+1)..<elements.count {
                    var e = elements[i]
                    e.y = y
                    e.display()
                    y += e.height
                }
            }
        }
        
        if cursorY != element.y {
            moveDown(cursorY - element.y - 1)
        }
        if let last = elements.last {
            cursorY = last.y + last.height
        }else{
            cursorY = 0
        }
    }
    enum ArrowDirection {
        case left
        case right
        case up
        case down
    }
    enum Keypress {
        case enter
        case printable(String)
        case abort
        case arrow(ArrowDirection)
        case delete
    }
    func waitForKeypress()-> Keypress {
        var buffer = Data()
        
        let abort = Data(bytes: [3])
        let enter0 = Data(bytes: [10])
        let enter1 = Data(bytes: [13])
        let delete = Data(bytes: [127])
        let at = Data(bytes: [27, 64])
        let up = Data(bytes: [27, 91, 65])
        let down = Data(bytes: [27, 91, 66])
        let right = Data(bytes: [27, 91, 67])
        let left = Data(bytes: [27, 91, 68])
        
        let a = Data(bytes: [27])
        let b = Data(bytes: [27, 91])
        repeat {
            let c = UInt8(getchar())
            buffer.append(c)
            
            if buffer == a || buffer == b {
                continue
            }
            
            if buffer == abort{
                close()
                exit(EXIT_FAILURE)
            }
            if buffer == enter0 || buffer == enter1 {
                return .enter
            }
            if buffer == delete {
                return .delete
            }
            if buffer == at {
                return .printable("@")
            }
            if buffer == up {
                return .arrow(.up)
            }
            if buffer == down {
                return .arrow(.down)
            }
            if buffer == right {
                return .arrow(.right)
            }
            if buffer == left {
                return .arrow(.left)
            }
            if let str = String(data: buffer, encoding: .utf8) {
                return .printable(str)
            }
            
        }while true
        
    }
}
