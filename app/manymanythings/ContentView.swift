//
//  ContentView.swift
//  manymanythings
//
//  Created by De-Great Yartey on 10/01/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            NavigationHost()
                .frame(maxHeight: .infinity, alignment: .top)

            Hr()

            TabsBar()
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
        }
        .frame(width: 230, height: 400)
    }
}

#Preview {
    ContentView()
        .environment(MenuBarIconManager())
        .environment(CalendarManager())
        .environment(EventKitManager())
        .environment(NavigationManager())
        .environment(TodoManager(context: PersistenceController.preview.container.viewContext))
        .environment(TodoFormState())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
