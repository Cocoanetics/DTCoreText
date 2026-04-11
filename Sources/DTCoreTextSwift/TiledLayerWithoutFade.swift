//
//  TiledLayerWithoutFade.swift
//  DTCoreText
//
//  Created by Oliver Drobnik on 8/24/11.
//  Copyright 2011 Cocoanetics. All rights reserved.
//
//  Migrated to Swift, April 2026.
//

#if canImport(UIKit) && !os(watchOS)
  import QuartzCore

  /// `CATiledLayer` subclass that disables the default fade-in of freshly
  /// rendered tiles. Overriding `fadeDuration` is the only supported way to
  /// turn the fade off — there is no public property for it.
  public final class TiledLayerWithoutFade: CATiledLayer {
    public override class func fadeDuration() -> CFTimeInterval {
      return 0
    }
  }
#endif
