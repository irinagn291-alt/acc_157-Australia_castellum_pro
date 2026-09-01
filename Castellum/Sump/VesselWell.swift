import SwiftUI
import UIKit

/// Role: Presentation. Hosts the communicating-vessel UIView. SwiftUI does not draw the water.
struct VesselWellHost: UIViewRepresentable {
    var vessels: WeirVessels
    var mark: DayMark?
    var reduceMotion: Bool
    var onPour: () -> Void

    func makeUIView(context: Context) -> VesselWellView {
        let view = VesselWellView()
        view.onPour = onPour
        return view
    }

    func updateUIView(_ uiView: VesselWellView, context: Context) {
        uiView.onPour = onPour
        uiView.apply(vessels: vessels, mark: mark, animated: !reduceMotion)
    }
}

/// Role: Presentation. Lower sump path and upper bowl path as CAShapeLayers. Tap pours 250 ml.
final class VesselWellView: UIView {
    var onPour: (() -> Void)?

    private let stoneLayer = CAShapeLayer()
    private let sumpFillLayer = CAShapeLayer()
    private let bowlFillLayer = CAShapeLayer()
    private let sumpLineLayer = CAShapeLayer()
    private let bowlLineLayer = CAShapeLayer()
    private let hatchLayer = CAShapeLayer()
    private let hatchBraceLayer = CAShapeLayer()

    private var vessels = WeirVessels.idle(sumpTarget: 0)
    private var mark: DayMark?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = CisternInk.backgroundUI
        isOpaque = true
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = "Pour two hundred fifty millilitres into the well"

        for layer in [sumpFillLayer, bowlFillLayer, stoneLayer, sumpLineLayer, bowlLineLayer, hatchLayer, hatchBraceLayer] {
            self.layer.addSublayer(layer)
        }

        stoneLayer.fillColor = nil
        stoneLayer.strokeColor = CisternInk.inkUI.cgColor
        stoneLayer.lineWidth = 2

        sumpFillLayer.fillColor = CisternInk.accentUI.cgColor
        bowlFillLayer.fillColor = CisternInk.accentUI.cgColor
        sumpFillLayer.strokeColor = nil
        bowlFillLayer.strokeColor = nil

        sumpLineLayer.fillColor = nil
        bowlLineLayer.fillColor = nil
        sumpLineLayer.strokeColor = CisternInk.inkUI.cgColor
        bowlLineLayer.strokeColor = CisternInk.inkUI.cgColor
        sumpLineLayer.lineWidth = 1
        bowlLineLayer.lineWidth = 1

        hatchLayer.fillColor = CisternInk.surfaceUI.cgColor
        hatchLayer.strokeColor = CisternInk.accentUI.cgColor
        hatchLayer.lineWidth = 2

        hatchBraceLayer.fillColor = CisternInk.inkUI.cgColor
        hatchBraceLayer.strokeColor = nil

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        rebuild(animated: false)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let padX = min(0, (bounds.width - CisternInk.tap) / 2)
        let padY = min(0, (bounds.height - CisternInk.tap) / 2)
        return bounds.insetBy(dx: padX, dy: padY).contains(point)
    }

    func apply(vessels: WeirVessels, mark: DayMark?, animated: Bool) {
        self.vessels = vessels
        self.mark = mark
        rebuild(animated: animated)
    }

    @objc private func handleTap() {
        onPour?()
    }

    private func rebuild(animated: Bool) {
        guard bounds.width > 8, bounds.height > 8 else { return }

        let inset = CisternInk.space(2)
        let field = bounds.insetBy(dx: inset, dy: inset)
        let bowlBox = CGRect(
            x: field.minX + field.width * 0.08,
            y: field.minY,
            width: field.width * 0.84,
            height: field.height * 0.42
        )
        let sumpBox = CGRect(
            x: field.minX + field.width * 0.16,
            y: field.minY + field.height * 0.58,
            width: field.width * 0.68,
            height: field.height * 0.38
        )
        let throat = CGRect(
            x: field.midX - CisternInk.space(3),
            y: bowlBox.maxY,
            width: CisternInk.space(6),
            height: sumpBox.minY - bowlBox.maxY
        )

        let stone = UIBezierPath()
        stone.append(chamberPath(bowlBox, notchAtBottom: true))
        stone.append(chamberPath(sumpBox, notchAtBottom: false))
        stone.move(to: CGPoint(x: throat.minX, y: throat.minY))
        stone.addLine(to: CGPoint(x: throat.minX, y: throat.maxY))
        stone.move(to: CGPoint(x: throat.maxX, y: throat.minY))
        stone.addLine(to: CGPoint(x: throat.maxX, y: throat.maxY))

        let sumpFraction = fillFraction(filled: vessels.sump.filledMillilitres, target: vessels.sump.depthMillilitres)
        let bowlTarget = mark?.bowlTarget ?? 0
        let bowlFraction = fillFraction(filled: vessels.bowl.millilitres, target: bowlTarget)

        let sumpWater = waterPath(in: sumpBox, fraction: sumpFraction, notchAtBottom: false)
        let bowlWater = waterPath(in: bowlBox, fraction: bowlFraction, notchAtBottom: true)

        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        CATransaction.setAnimationDuration(animated ? 0.28 : 0)
        stoneLayer.path = stone.cgPath
        sumpFillLayer.path = sumpWater.cgPath
        bowlFillLayer.path = bowlWater.cgPath
        sumpLineLayer.path = waterline(in: sumpBox, fraction: sumpFraction)
        bowlLineLayer.path = waterline(in: bowlBox, fraction: bowlFraction)
        hatchLayer.path = hatchPath(throat: throat, open: vessels.weir == .openSump).cgPath
        hatchBraceLayer.path = hatchBrace(throat: throat, open: vessels.weir == .openSump).cgPath
        CATransaction.commit()
    }

    private func fillFraction(filled: Int, target: Int) -> CGFloat {
        guard target > 0 else { return filled > 0 ? 1 : 0 }
        return min(1, max(0, CGFloat(filled) / CGFloat(target)))
    }

    private func chamberPath(_ box: CGRect, notchAtBottom: Bool) -> UIBezierPath {
        let path = UIBezierPath()
        let notch = CisternInk.space(2)
        path.move(to: CGPoint(x: box.minX, y: box.minY))
        path.addLine(to: CGPoint(x: box.maxX, y: box.minY))
        path.addLine(to: CGPoint(x: box.maxX, y: box.maxY))
        if notchAtBottom {
            path.addLine(to: CGPoint(x: box.midX + notch, y: box.maxY))
            path.addLine(to: CGPoint(x: box.midX, y: box.maxY - notch))
            path.addLine(to: CGPoint(x: box.midX - notch, y: box.maxY))
        }
        path.addLine(to: CGPoint(x: box.minX, y: box.maxY))
        path.close()
        return path
    }

    private func waterPath(in box: CGRect, fraction: CGFloat, notchAtBottom: Bool) -> UIBezierPath {
        guard fraction > 0 else { return UIBezierPath() }
        let height = box.height * fraction
        var water = CGRect(x: box.minX + 3, y: box.maxY - height, width: box.width - 6, height: height)
        water = water.intersection(box.insetBy(dx: 3, dy: 3))
        if water.isNull || water.height < 1 { return UIBezierPath() }
        if notchAtBottom, fraction > 0.92 {
            return chamberPath(water, notchAtBottom: true)
        }
        return UIBezierPath(rect: water)
    }

    private func waterline(in box: CGRect, fraction: CGFloat) -> CGPath {
        guard fraction > 0 else { return CGPath(rect: .zero, transform: nil) }
        let y = box.maxY - box.height * fraction
        let path = UIBezierPath()
        path.move(to: CGPoint(x: box.minX + 4, y: y))
        path.addLine(to: CGPoint(x: box.maxX - 4, y: y))
        return path.cgPath
    }

    private func hatchPath(throat: CGRect, open: Bool) -> UIBezierPath {
        let lip = CGRect(
            x: throat.minX - CisternInk.space(1),
            y: throat.midY - 5,
            width: throat.width + CisternInk.space(2),
            height: 10
        )
        if open {
            let door = UIBezierPath()
            door.move(to: CGPoint(x: lip.minX, y: lip.minY))
            door.addLine(to: CGPoint(x: lip.maxX + CisternInk.space(2), y: lip.minY - CisternInk.space(2)))
            door.addLine(to: CGPoint(x: lip.maxX + CisternInk.space(2), y: lip.maxY - CisternInk.space(1)))
            door.addLine(to: CGPoint(x: lip.minX, y: lip.maxY))
            door.close()
            return door
        }
        return UIBezierPath(rect: lip)
    }

    private func hatchBrace(throat: CGRect, open: Bool) -> UIBezierPath {
        let mark = UIBezierPath()
        if open {
            let tip = CGPoint(x: throat.maxX + CisternInk.space(3), y: throat.midY - CisternInk.space(2))
            mark.move(to: tip)
            mark.addLine(to: CGPoint(x: tip.x + 8, y: tip.y + 4))
            mark.addLine(to: CGPoint(x: tip.x, y: tip.y + 8))
            mark.close()
        } else {
            mark.move(to: CGPoint(x: throat.midX - 6, y: throat.midY))
            mark.addLine(to: CGPoint(x: throat.midX + 6, y: throat.midY))
        }
        return mark
    }
}
