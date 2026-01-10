//
//  Hr.swift
//  hasul
//
//  Created by De-Great Yartey on 10/01/2026.
//

import SwiftUI

struct Hr: View {
    var body: some View {
        HStack {
            Rectangle().fill(Color.secondary.opacity(0.3))
                .frame(width: 44, height: 4)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}
