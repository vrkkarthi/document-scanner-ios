struct RectangleFeature {
    let topLeft: CGPoint
    let topRight: CGPoint
    let bottomLeft: CGPoint
    let bottomRight: CGPoint

    init(topLeft: CGPoint = .zero,
         topRight: CGPoint = .zero,
         bottomLeft: CGPoint = .zero,
         bottomRight: CGPoint = .zero) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomLeft = bottomLeft
        self.bottomRight = bottomRight
    }
}

extension RectangleFeature {
    init(_ rectangleFeature: CIRectangleFeature) {
        topLeft = rectangleFeature.topLeft
        topRight = rectangleFeature.topRight
        bottomLeft = rectangleFeature.bottomLeft
        bottomRight = rectangleFeature.bottomRight
    }

    func smoothed(with previous: [RectangleFeature]) -> (RectangleFeature, [RectangleFeature]) {

        let allFeatures = [self] + previous
        let smoothed = allFeatures.average

        return (smoothed, Array(allFeatures.prefix(10)))
    }

    func normalized(source: CGSize, target: CGSize) -> RectangleFeature {
        let distortion = CGVector(dx: target.width / source.width,
                                  dy: target.height / source.height)

        func normalize(_ point: CGPoint) -> CGPoint {
            return point.yAxisInverted(source.height).distorted(by: distortion)
        }

        return RectangleFeature(
            topLeft: normalize(topLeft),
            topRight: normalize(topRight),
            bottomLeft: normalize(bottomLeft),
            bottomRight: normalize(bottomRight)
        )
    }

    var bezierPath: UIBezierPath {

        let path = UIBezierPath()
        path.move(to: topLeft)
        path.addLine(to: topRight)
        path.addLine(to: bottomRight)
        path.addLine(to: bottomLeft)
        path.close()

        return path
    }

    func difference(to: RectangleFeature) -> CGFloat {
            return
                abs(to.topLeft - topLeft) +
                abs(to.topRight - topRight) +
                abs(to.bottomLeft - bottomLeft) +
                abs(to.bottomRight - bottomRight)
    }

    /// This isn't the real area, but enables correct comparison
    private var areaQualifier: CGFloat {
        let diagonalToLeft = (topRight - bottomLeft)
        let diagonalToRight = (topLeft - bottomRight)
        let phi = diagonalToLeft.x * diagonalToRight.x + diagonalToLeft.y * diagonalToRight.y / (diagonalToLeft.length * diagonalToRight.length)
        return sqrt(1 - phi * phi) * diagonalToLeft.length * diagonalToRight.length
    }
}

extension RectangleFeature: Comparable {
    static func < (lhs: RectangleFeature, rhs: RectangleFeature) -> Bool {
        return lhs.areaQualifier < rhs.areaQualifier
    }

    static func == (lhs: RectangleFeature, rhs: RectangleFeature) -> Bool {
        return lhs.topLeft == rhs.topLeft
            && lhs.topRight == rhs.topRight
            && lhs.bottomLeft == rhs.bottomLeft
            && lhs.bottomRight == rhs.bottomRight
    }
}

private extension CGPoint {
    func distorted(by distortion: CGVector) -> CGPoint {
        return CGPoint(x: x * distortion.dx, y: y * distortion.dy)
    }

    func yAxisInverted(_ maxY: CGFloat) -> CGPoint {
        return CGPoint(x: x, y: maxY - y)
    }

    var length: CGFloat {
        return sqrt(x * x + y * y)
    }
}
