//
//  TabBarItem.swift
//  CodeEdit
//
//  Created by Lukas Pistrol on 17.03.22.
//

import SwiftUI
import WorkspaceClient

struct TabDivider: View {
    @Environment(\.colorScheme) var colorScheme
    let width: CGFloat = 1

    var body: some View {
        Group {
            Rectangle()
        }
        .frame(width: width)
        .foregroundColor(
            Color(nsColor: colorScheme == .dark ? .white : .black)
                .opacity(colorScheme == .dark ? 0.08 : 0.12)
        )
    }
}

struct TabBarItem: View {
    @Environment(\.colorScheme) var colorScheme
    @State var isHovering: Bool = false
    @State var isHoveringClose: Bool = false
    @State var isPressingClose: Bool = false
    
    var item: WorkspaceClient.FileItem
    var windowController: NSWindowController
    
    func closeAction () {
        withAnimation() {
            workspace.closeFileTab(item: item)
        }
    }

    @ObservedObject var workspace: WorkspaceDocument
    var tabBarHeight: Double = 28.0
    var isActive: Bool {
        item.id == workspace.selectedId
    }
    
    @ViewBuilder
    var content: some View {
        HStack(spacing: 0.0) {
            TabDivider()
            HStack(alignment: .center, spacing: 5) {
                ZStack {
                    if isActive {
                        // Create a hidden button, if the tab is selected
                        // and hide the button in the ZStack.
                        Button(action: closeAction) {
                            Text("").hidden()
                        }
                        .frame(width: 0, height: 0)
                        .padding(0)
                        .opacity(0)
                        .keyboardShortcut("w", modifiers: [.command])
                    }
                    Button(action: closeAction) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9.5, weight: .medium, design: .rounded))
                            .frame(width: 16, height: 16)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(isPressingClose ? .primary : .secondary)
                    .background(colorScheme == .dark
                        ? isPressingClose
                            ? Color(nsColor: .white).opacity(0.32)
                            : isHoveringClose
                                    ? Color(nsColor: .white).opacity(0.18)
                                    : Color(.clear)
                        : isPressingClose
                                ? Color(nsColor: .black).opacity(0.29)
                                : isHoveringClose
                                        ? Color(nsColor: .black).opacity(0.11)
                                        : Color(.clear)
                    )
                    .cornerRadius(2)
                    .accessibilityLabel(Text("Close"))
                    .onHover { hover in
                        isHoveringClose = hover
                    }
                    .pressAction {
                        isPressingClose = true
                    } onRelease: {
                        isPressingClose = false
                    }
                    .opacity(isHovering ? 1 : 0)
                }
                Image(systemName: item.systemImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12, height: 12)
                Text(item.url.lastPathComponent)
                    .font(.system(size: 11.0))
                    .lineLimit(1)
            }
            .frame(height: 28)
            .padding(.leading, 4)
            .padding(.trailing, 28)
            .background(
                Color(nsColor: isActive ? .clear : .black)
                    .opacity(
                        colorScheme == .dark
                            ? isHovering ? 0.15 : isActive ? 0 : 0.45
                            : isHovering ? 0.15 : isActive ? 0 : 0.05
                    )
                    .animation(.easeInOut(duration: 0.15))
            )
            TabDivider()
        }
        .frame(height: tabBarHeight)
        .foregroundColor(isActive ? .primary : .secondary)
        .onHover { hover in
            isHovering = hover
            DispatchQueue.main.async {
                if hover {
                    NSCursor.arrow.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
    }
    
    var body: some View {
        Button(
            action: { workspace.selectedId = item.id },
            label: { content }
        )
        .background(BlurView(
            material: NSVisualEffectView.Material.titlebar,
            blendingMode: NSVisualEffectView.BlendingMode.withinWindow
        ))
        .animation(.easeOut(duration: 0.2), value: workspace.openFileItems)
        .buttonStyle(.plain)
        .id(item.id)
        .keyboardShortcut(
            workspace.getTabKeyEquivalent(item: item),
            modifiers: [.command]
        )
        .contextMenu {
            Button("Close Tab") {
                withAnimation {
                    workspace.closeFileTab(item: item)
                }
            }
            Button("Close Other Tabs") {
                withAnimation {
                    workspace.closeFileTab(where: { $0.id != item.id })
                }
            }
            Button("Close Tabs to the Right") {
                withAnimation {
                    workspace.closeFileTabs(after: item)
                }
            }
        }
    }
}

fileprivate extension WorkspaceDocument {
    func getTabKeyEquivalent(item: WorkspaceClient.FileItem) -> KeyEquivalent {
        for counter in 0..<9 where self.openFileItems.count > counter &&
        self.openFileItems[counter].fileName == item.fileName {
            return KeyEquivalent.init(
                Character.init("\(counter + 1)")
            )
        }

        return "0"
    }
}
