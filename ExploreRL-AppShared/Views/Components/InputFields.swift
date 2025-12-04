//
//  InputFields.swift
//

import SwiftUI

struct DoubleInputField: View {
    @Binding var value: Double
    var decimals: Int = 2
    var width: CGFloat = 80
    
    private var format: FloatingPointFormatStyle<Double> {
        FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0...decimals))
    }
    
    var body: some View {
        TextField("", value: $value, format: format)
            .textFieldStyle(.roundedBorder)
            .frame(width: width)
            .multilineTextAlignment(.trailing)
    #if os(iOS)
            .keyboardType(.decimalPad)
    #endif
    }
}

struct IntInputField: View {
    @Binding var value: Int
    var width: CGFloat = 80
    
    var body: some View {
        TextField("", value: $value, format: .number)
            .textFieldStyle(.roundedBorder)
            .frame(width: width)
            .multilineTextAlignment(.trailing)
    #if os(iOS)
            .keyboardType(.numberPad)
    #endif
    }
}

