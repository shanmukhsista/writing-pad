//
//  ContentView.swift
//  WritingPad
//
//  Created by Shanmukh Sista on 9/17/23.
//

import SwiftUI
import AlertToast
struct Line {
    
    var points = [CGPoint]()
    var color : Color = .white
    var lineWidth : Double = 2
    
    init(color : Color){
        self.color = color
    }
}

struct PageDrawingContent {
    var currentLine : Line
    var lines : [Line]
}

struct UndoState{
    var point : CGPoint?
    var line : Line?
    var page : Int?
}

struct ContentView: View {
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var currentPageIndex : Int = 0
    @State private var currentColor :  Color = Color.white
    @State var pagesMap: [Int: PageDrawingContent] = [0:PageDrawingContent(currentLine: Line(color: .white), lines: [])]
    
    @State private var undostate : [UndoState] = []
    
    var body: some View {
        VStack {
            Canvas{context,size in
                for line in
                        pagesMap[currentPageIndex]!.lines {
                    var path = Path()
                    path.addLines(line.points)
                    context.stroke(path, with: .color(line.color), lineWidth: line.lineWidth)
                }
            }.gesture(DragGesture(minimumDistance: 0.0 , coordinateSpace: .local).onChanged({value in
                var currentPage =  pagesMap[currentPageIndex]!
                let newPoint = value.location
                if currentPage.currentLine.color != currentColor {
                    currentPage.currentLine = Line(color: currentColor)
                }
                currentPage.currentLine.points.append(newPoint)
                currentPage.lines.append( currentPage.currentLine)
                self.pagesMap[self.currentPageIndex] = currentPage
               
            }).onEnded({value in
                var currentPage =  pagesMap[currentPageIndex]!
                currentPage.lines.append( currentPage.currentLine)
                currentPage.currentLine = Line(color: currentColor)
                pagesMap[self.currentPageIndex] = currentPage
            }))
        }.frame(minWidth: 400, minHeight: 400)
        .padding().toolbar(id: "items") {
            ToolbarItem(id: "media") {
                ControlGroup {
                    
                    Button(action: undoStroke) {Image(systemName:"arrow.uturn.backward")}.keyboardShortcut("z")
                    Button(action: redoStroke) {Image(systemName:"arrow.uturn.forward")}.keyboardShortcut("z", modifiers: [ .command,.shift])
                    ColorPicker("Set the background color", selection: $currentColor)

                    Button("Clear Page"){
                        self.pagesMap[self.currentPageIndex] = PageDrawingContent(currentLine: Line(color: currentColor), lines: [])
                    }
                    Button(action:{
                        if self.currentPageIndex == 0 {
                            return
                        }
                        let nextPage = self.currentPageIndex - 1
                        if !self.pagesMap.keys.contains(nextPage){
                            self.pagesMap[nextPage] = PageDrawingContent(currentLine: Line(color: currentColor), lines: [])
                        }
                        self.currentPageIndex -= 1
                        self.toastMessage = "Page \(self.currentPageIndex+1)"
                        self.showToast = true
                    }){Image(systemName: "backward.frame")}.keyboardShortcut("<")
                    Text("Page \(self.currentPageIndex + 1) of \(self.pagesMap.count)")
                    Button(action:{
                        let nextPage = self.currentPageIndex + 1
                        if !self.pagesMap.keys.contains(nextPage){
                            self.pagesMap[nextPage] = PageDrawingContent(currentLine: Line(color: currentColor), lines: [])
                        }
                        self.currentPageIndex += 1
                        self.toastMessage = "Page \(self.currentPageIndex+1)"
                        self.showToast = true
                    }){Image(systemName: "forward.frame")}.keyboardShortcut(">")
                } label: {
                    Label("Plus", systemImage: "plus")
                }
            }
        }.toast(isPresenting: $showToast,duration: 1){
            // `.alert` is the default displayMode
            AlertToast(type: .complete(.white), title: toastMessage)
        }
    }
    
    
    func undoStroke(){
        var numTimes = 10
        var undostates : [UndoState] = []
        while numTimes > 0 {
            var us = UndoState()
            us.page = self.currentPageIndex
            if let lastPoint = self.pagesMap[self.currentPageIndex]?.currentLine.points.popLast() {
                us.point = lastPoint
            }
             if let lastLine = self.pagesMap[self.currentPageIndex]?.lines.popLast() {
                 us.line = lastLine
            }
            undostates.append(us)
            numTimes -= 1
        }
        self.undostate.append(contentsOf: undostates)
    }
    
    func redoStroke(){
        var numTimes = 10
        while numTimes > 0 {
            if let undostate = self.undostate.popLast() {
                print(undostate)
                
                if let currentPage = undostate.page , let lastPoint = undostate.point{
                    self.pagesMap[currentPage]?.currentLine.points.append(lastPoint)
                }
                
                if  let lastLine = undostate.line,let currentPage = undostate.page {
                    self.pagesMap[currentPage]?.lines.append(lastLine)
                }
            }
            numTimes -= 1
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
