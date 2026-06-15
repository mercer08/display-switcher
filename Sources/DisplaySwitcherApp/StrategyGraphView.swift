import SwiftUI

struct StrategyGraphView: View {
    @EnvironmentObject private var appState: AppState
    let group: SwitchGroup

    private var routes: [GraphRoute] {
        group.rules.map { rule in
            let targetSlot = rule.targetSlot.isEmpty ? appState.sourceName(displayID: rule.displayID, value: rule.sourceValue, fallback: rule.sourceName) : rule.targetSlot
            let cableType = rule.cableType.isEmpty ? cableTypeFallback(for: targetSlot) : rule.cableType
            let sourceSlot = rule.sourceSlot.isEmpty ? "USB-C" : rule.sourceSlot
            let sourceName = rule.sourceDeviceName.isEmpty ? appState.t(.manual) : localizedSourceDevice(rule.sourceDeviceName)
            return GraphRoute(
                id: rule.id,
                sourceID: sourceName,
                sourceName: sourceName,
                sourceDetail: sourceSlot,
                lineID: rule.id.uuidString,
                lineName: cableType,
                lineDetail: "\(sourceSlot) → \(targetSlot)",
                category: category(for: rule, sourceName: targetSlot),
                targetID: rule.displayID,
                targetName: displayName(for: rule),
                targetDetail: displayDetail(for: rule),
                isEnabled: rule.enabled && !rule.sourceValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
        }
    }

    private var sourceNodes: [GraphSourceNode] {
        Dictionary(grouping: routes, by: \.sourceID)
            .values
            .compactMap { groupedRoutes in
                guard let first = groupedRoutes.first else { return nil }
                return GraphSourceNode(
                    id: first.sourceID,
                    name: first.sourceName,
                    detail: first.sourceDetail,
                    activeCount: groupedRoutes.filter(\.isEnabled).count
                )
            }
            .sorted {
                if $0.sortRank != $1.sortRank {
                    return $0.sortRank < $1.sortRank
                }
                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
    }

    private var lineNodes: [GraphLineNode] {
        routes.map {
            GraphLineNode(
                id: $0.lineID,
                name: $0.lineName,
                detail: $0.lineDetail,
                category: $0.category,
                isEnabled: $0.isEnabled
            )
        }
    }

    private var targetNodes: [GraphTargetNode] {
        routes.map {
            GraphTargetNode(
                id: $0.targetID,
                name: $0.targetName,
                detail: $0.targetDetail
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(appState.t(.graphPreview))
                        .font(.headline)
                    Text(appState.t(.graphPreviewDescription))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 10) {
                    LegendDot(color: .teal, label: appState.t(.activeRoute))
                    LegendDot(color: .secondary, label: appState.t(.inactiveRoute))
                }
            }

            GeometryReader { proxy in
                let layout = GraphLayout(
                    size: proxy.size,
                    sourceNodes: sourceNodes,
                    lineNodes: lineNodes,
                    targetNodes: targetNodes,
                    routes: routes
                )

                ZStack {
                    Canvas { context, _ in
                        for route in routes {
                            drawRoute(route, layout: layout, context: &context)
                        }
                    }

                    ForEach(sourceNodes) { node in
                        GraphNodeCard(
                            title: node.name,
                            subtitle: node.detail,
                            systemImage: "laptopcomputer",
                            tint: .teal,
                            badge: node.activeCount > 1 ? "×\(node.activeCount)" : nil
                        )
                        .frame(width: layout.sourceWidth)
                        .position(layout.sourceCardPosition(for: node.id))
                    }

                    ForEach(lineNodes) { node in
                        GraphNodeCard(
                            title: node.name,
                            subtitle: node.detail,
                            systemImage: node.category.symbolName,
                            tint: node.isEnabled ? node.category.tintColor : .secondary,
                            badge: nil
                        )
                        .frame(width: layout.lineWidth)
                        .position(layout.lineCardPosition(for: node.id))
                    }

                    ForEach(targetNodes) { node in
                        GraphNodeCard(
                            title: node.name,
                            subtitle: node.detail,
                            systemImage: "display",
                            tint: .blue,
                            badge: nil
                        )
                        .frame(width: layout.targetWidth)
                        .position(layout.targetCardPosition(for: node.id))
                    }

                    Text(appState.t(.sourceDevices))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .position(x: layout.sourceX, y: 12)

                    Text(appState.t(.lineAndSlots))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .position(x: layout.lineX, y: 12)

                    Text(appState.t(.outputDisplays))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .position(x: layout.targetX, y: 12)
                }
            }
            .frame(height: graphHeight)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 8).fill(AppColors.secondaryBackground))
        }
    }

    private var graphHeight: CGFloat {
        let rows = max(sourceNodes.count, lineNodes.count, targetNodes.count)
        return CGFloat(max(2, rows)) * 76 + 36
    }

    private func drawRoute(_ route: GraphRoute, layout: GraphLayout, context: inout GraphicsContext) {
        guard let source = layout.sourcePoint(for: route.sourceID),
              let lineLeft = layout.lineLeftPoint(for: route.lineID),
              let lineRight = layout.lineRightPoint(for: route.lineID),
              let target = layout.targetPoint(for: route.targetID) else { return }

        let color = route.isEnabled ? route.category.tintColor : Color.secondary.opacity(0.45)
        let style = StrokeStyle(lineWidth: route.isEnabled ? 2.6 : 1.4, lineCap: .round, dash: route.isEnabled ? [] : [5, 5])

        context.stroke(curve(from: source, to: lineLeft), with: .color(color), style: style)
        context.stroke(curve(from: lineRight, to: target), with: .color(color), style: style)
    }

    private func curve(from start: CGPoint, to end: CGPoint) -> Path {
        var path = Path()
        path.move(to: start)
        let distance = max(50, end.x - start.x)
        path.addCurve(
            to: end,
            control1: CGPoint(x: start.x + distance * 0.45, y: start.y),
            control2: CGPoint(x: end.x - distance * 0.45, y: end.y)
        )
        return path
    }

    private func localizedSourceDevice(_ value: String) -> String {
        if value == "Work MacBook Pro" || value == "工作 MacBook Pro" {
            return Localization.text(.presetWorkBothName, language: appState.language)
        }
        if value == "Personal Mac" || value == "个人 Mac" {
            return Localization.text(.presetPersonalBothName, language: appState.language)
        }
        return value
    }

    private func displayName(for rule: SwitchRule) -> String {
        appState.displays.first { $0.id == rule.displayID }?.name ?? rule.displayName
    }

    private func displayDetail(for rule: SwitchRule) -> String {
        appState.displays.first { $0.id == rule.displayID }?.shortIdentity ?? appState.t(.disconnectedDisplay)
    }

    private func category(for rule: SwitchRule, sourceName: String) -> SourceCategory {
        if let source = appState.inputSourcesByDisplayID[rule.displayID]?.first(where: { $0.value == rule.sourceValue }) {
            return source.category
        }
        return InputSource(value: rule.sourceValue, name: sourceName, controller: nil).category
    }

    private func cableTypeFallback(for sourceName: String) -> String {
        let lower = sourceName.lowercased()
        if lower.contains("usb-c") || lower.contains("usb c") || lower.contains("tb") {
            return "Type-C ↔ Type-C"
        }
        if lower.contains("displayport") || lower.hasPrefix("dp ") || lower.contains(" dp ") {
            return "Type-C → DisplayPort"
        }
        if lower.contains("hdmi") {
            return "Type-C → HDMI"
        }
        return "Input cable"
    }
}

private struct GraphNodeCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let badge: String?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 7).fill(tint.opacity(0.13)))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            if let badge {
                Text(badge)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(tint)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(tint.opacity(0.12)))
            }
        }
        .padding(9)
        .background(RoundedRectangle(cornerRadius: 8).fill(AppColors.cardBackground))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border, lineWidth: 1))
    }
}

private struct LegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct GraphRoute: Identifiable {
    var id: UUID
    var sourceID: String
    var sourceName: String
    var sourceDetail: String
    var lineID: String
    var lineName: String
    var lineDetail: String
    var category: SourceCategory
    var targetID: String
    var targetName: String
    var targetDetail: String
    var isEnabled: Bool
}

private struct GraphSourceNode: Identifiable {
    var id: String
    var name: String
    var detail: String
    var activeCount: Int

    var sortRank: Int {
        if name.localizedCaseInsensitiveContains("work") || name.localizedCaseInsensitiveContains("工作") {
            return 0
        }
        if name.localizedCaseInsensitiveContains("personal") || name.localizedCaseInsensitiveContains("个人") {
            return 1
        }
        return 2
    }
}

private struct GraphLineNode: Identifiable {
    var id: String
    var name: String
    var detail: String
    var category: SourceCategory
    var isEnabled: Bool
}

private struct GraphTargetNode: Identifiable {
    var id: String
    var name: String
    var detail: String
}

private struct GraphLayout {
    let size: CGSize
    let sourceNodes: [GraphSourceNode]
    let lineNodes: [GraphLineNode]
    let targetNodes: [GraphTargetNode]
    let routes: [GraphRoute]

    var sourceWidth: CGFloat { min(190, max(145, size.width * 0.22)) }
    var lineWidth: CGFloat { min(230, max(170, size.width * 0.26)) }
    var targetWidth: CGFloat { min(210, max(155, size.width * 0.24)) }

    var sourceX: CGFloat { sourceWidth / 2 + 18 }
    var lineX: CGFloat { size.width * 0.49 }
    var targetX: CGFloat { max(lineX + lineWidth / 2 + targetWidth / 2 + 90, size.width - targetWidth / 2 - 18) }

    func sourceCardPosition(for id: String) -> CGPoint {
        CGPoint(x: sourceX, y: yPosition(index: sourceIndex(for: id), count: sourceNodes.count))
    }

    func lineCardPosition(for id: String) -> CGPoint {
        CGPoint(x: lineX, y: yPosition(index: lineIndex(for: id), count: lineNodes.count))
    }

    func targetCardPosition(for id: String) -> CGPoint {
        CGPoint(x: targetX, y: yPosition(index: targetIndex(for: id), count: targetNodes.count))
    }

    func sourcePoint(for id: String) -> CGPoint? {
        guard sourceNodes.contains(where: { $0.id == id }) else { return nil }
        let position = sourceCardPosition(for: id)
        return CGPoint(x: position.x + sourceWidth / 2, y: position.y)
    }

    func lineLeftPoint(for id: String) -> CGPoint? {
        guard lineNodes.contains(where: { $0.id == id }) else { return nil }
        let position = lineCardPosition(for: id)
        return CGPoint(x: position.x - lineWidth / 2, y: position.y)
    }

    func lineRightPoint(for id: String) -> CGPoint? {
        guard lineNodes.contains(where: { $0.id == id }) else { return nil }
        let position = lineCardPosition(for: id)
        return CGPoint(x: position.x + lineWidth / 2, y: position.y)
    }

    func targetPoint(for id: String) -> CGPoint? {
        guard targetNodes.contains(where: { $0.id == id }) else { return nil }
        let position = targetCardPosition(for: id)
        return CGPoint(x: position.x - targetWidth / 2, y: position.y)
    }

    private func sourceIndex(for id: String) -> Int {
        sourceNodes.firstIndex { $0.id == id } ?? 0
    }

    private func lineIndex(for id: String) -> Int {
        lineNodes.firstIndex { $0.id == id } ?? 0
    }

    private func targetIndex(for id: String) -> Int {
        targetNodes.firstIndex { $0.id == id } ?? 0
    }

    private func yPosition(index: Int, count: Int) -> CGFloat {
        let top: CGFloat = 58
        let bottom: CGFloat = 34
        let available = max(1, size.height - top - bottom)
        guard count > 1 else { return top + available / 2 }
        return top + available * CGFloat(index) / CGFloat(count - 1)
    }
}

private extension SourceCategory {
    var tintColor: Color {
        switch self {
        case .usbC: return .teal
        case .displayPort: return .blue
        case .hdmi: return .orange
        case .dviVga: return .purple
        case .legacy: return .secondary
        case .other: return .gray
        }
    }
}
