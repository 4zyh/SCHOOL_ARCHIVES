import UIKit

extension CGImagePropertyOrientation {
  init(_ orientation: UIImageOrientation) {
    switch orientation {
    case .up: self = .up
    case .upMirrored: self = .upMirrored
    case .down