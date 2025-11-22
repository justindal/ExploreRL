//
//  PolicyOverlayView.swift
//

import SwiftUI

struct PolicyOverlayView: View {
    let map: [String]
    let policy: [Int]
    
    var rows: Int { map.count }
    var cols: Int { map.first?.count ?? 0 }
    
    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                drawPolicy(context: &context, size: size)
            }
        }
        .aspectRatio(CGFloat(cols) / CGFloat(rows), contentMode: .fit)
    }
    
    private func cellSize(for size: CGSize) -> CGSize {
        guard rows > 0, cols > 0 else { return .zero }
        return CGSize(width: size.width / CGFloat(cols), height: size.height / CGFloat(rows))
    }
    
    private func drawPolicy(context: inout GraphicsContext, size: CGSize) {
        guard rows > 0, cols > 0 else { return }
        let cell = cellSize(for: size)
        let arrowSize = min(cell.width, cell.height) * 0.3
        
        for (index, direction) in policy.enumerated() {
            guard index < rows * cols else { continue }
            
            let row = index / cols
            let col = index % cols
            
            let rowString = map[row]
            let charIndex = rowString.index(rowString.startIndex, offsetBy: col)
            let tile = rowString[charIndex]
            
            if tile == "H" || tile == "G" { continue }
            
            let centerX = CGFloat(col) * cell.width + cell.width / 2
            let centerY = CGFloat(row) * cell.height + cell.height / 2
            
            context.drawLayer { ctx in
                ctx.translateBy(x: centerX, y: centerY)
                
                let angle: Angle
                switch direction {
                case 0: angle = .degrees(180) 
                case 1: angle = .degrees(90)  
                case 2: angle = .degrees(0)   
                case 3: angle = .degrees(-90) 
                default: angle = .degrees(0)
                }
                
                ctx.rotate(by: angle)
                
                var path = Path()
                path.move(to: CGPoint(x: -arrowSize/2, y: 0))
                path.addLine(to: CGPoint(x: arrowSize/2, y: 0))
                path.addLine(to: CGPoint(x: 0, y: -arrowSize/3))
                path.move(to: CGPoint(x: arrowSize/2, y: 0))
                path.addLine(to: CGPoint(x: 0, y: arrowSize/3))
                
                ctx.stroke(path, with: .color(.black.opacity(0.4)), lineWidth: 2)
            }
        }
    }
}

