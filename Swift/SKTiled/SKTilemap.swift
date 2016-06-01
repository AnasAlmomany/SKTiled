//
//  SKTilemap.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


// MARK: - Protocols

/* generic SKTilemap object */
protocol TiledObject {
    var uuid: String { get set }                  // unique id (layer object names are not unique).
    var properties: [String: String] { get set }  // properties shared by most objects.
    // size
    var anchorPoint: CGPoint { get set }          // emulates a sprite node.
    var size: CGSize { get }                      // emulates a sprite node.
    var visible: Bool { get set }
    
    var center: CGPoint { get }
    func distanceFromOrigin(pos: CGPoint) -> CGVector
}


// screen format
public enum ScreenFormat: Int {
    case Universal
    case Portrait
    case Landscape
}

// MARK: - Tiled File Properties
public enum TilemapOrientation: String {
    case Orthogonal   = "orthogonal"
    case Isometric    = "isometric"
    case Hexagonal    = "hexagonal"
    case Staggered    = "staggered"
}


public enum RenderOrder: String {
    case RightDown  = "right-down"
    case RightUp    = "right-up"
    case LeftDown   = "left-down"
    case LeftUp     = "left-up"
}


public enum TilemapEncoding: String {
    case Base64  = "base64"
    case CSV     = "csv"
    case XML     = "xml"
}


/* valid property types */
public enum PropertyType: String {
    case bool
    case int
    case float
    case string
}


public enum FlippedFlags: CUnsignedLong {
    case Horizontal = 0x80000000
    case Vertical   = 0x40000000
    case Diagonal   = 0x20000000
}


/* generic property */
public struct Property {
    public var name: String
    public var value: AnyObject
    public var type: PropertyType = .string
}


// MARK: - Sizing
public struct TileSize {
    public var width: CGFloat
    public var height: CGFloat
}


public struct TileCoord {
    public var x: Int32
    public var y: Int32
    
    public init(_ x: Int32, _ y: Int32){
        self.x = x
        self.y = y
    }
}


public var TileSizeZero = TileSize(width: 0, height: 0)
public var TileSize8x8  = TileSize(width: 8, height: 8)
public var TileSize16x16 = TileSize(width: 16, height: 16)



public struct MapSize {
    public var width: CGFloat
    public var height: CGFloat
    public var tileSize: TileSize = TileSize8x8
}


public class SKTilemap: SKNode {
    
    public var mapSize: MapSize
    public var orientation: TilemapOrientation!
    // current tile sets
    public var tileSets: Set<SKTileset> = []
    
    // current layers
    public var layers: Set<TiledLayerObject> = []
    public var properties: [String: String] = [:]
    public var zDeltaForLayers: CGFloat = 50
    
    // debugging
    public var debugLabel: SKLabelNode!
    public var debugColor: SKColor = SKColor(red: 0.5, green: 0, blue: 0.5, alpha: 1)
    
    // emulate size & anchor point
    public var size: CGSize { return mapSize.renderSize }
    public var anchorPoint: CGPoint { return CGPointMake(0.5, 0.5) }
    // return the center position for layer nodes
    public var center: CGPoint {
        return CGPointMake(-size.width * anchorPoint.x, size.height - anchorPoint.y * size.height * anchorPoint.y)
    }
    
    public var renderSize: CGSize {
        return mapSize.renderSize
    }
    
    public var tileSize: TileSize {
        return mapSize.tileSize
    }
    
    // returns the last GID for all of the tilesets.
    public var lastGID: Int {
        return tileSets.count > 0 ? tileSets.map {$0.lastGID}.maxElement()! : 0
    }    
    
    /// Returns the last GID for all of the tilesets.
    public var lastIndex: Int {
        return layers.count > 0 ? layers.map {$0.index}.maxElement()! : 0
    }
    
    public var lastZPosition: CGFloat {
        return layers.count > 0 ? layers.map {$0.zPosition}.maxElement()! : 0
    }
    
    /// Convenience property to return all tile layers.
    public var tileLayers: [SKTileLayer] {
        var layers: [SKTileLayer] = []
        // use `SKTilemap.getLayers` to return sorted layers.
        for layer in getLayers() {
            if let layer = layer as? SKTileLayer {
                layers.append(layer)
            }
        }
        return layers
    }
    
    /// Convenience property to return all object groups.
    public var objectGroups: [SKObjectGroup] {
        var layers: [SKObjectGroup] = []
        for layer in getLayers() {
            if let layer = layer as? SKObjectGroup {
                layers.append(layer)
            }
        }
        return layers
    }
    
    /// Convenience property to return all image layers.
    public var imageLayers: [SKImageLayer] {
        var layers: [SKImageLayer] = []
        for layer in getLayers() {
            if let layer = layer as? SKImageLayer {
                layers.append(layer)
            }
        }
        return layers
    }
    
    
    // MARK: - Loading
    public class func loadFromFile(fileNamed: String) -> SKTilemap? {
        if let tilemap = SKTilemapParser().loadFromFile(fileNamed) {
            return tilemap
        }
        return nil
    }
    
    // MARK: - Init
    /**
     Initialize with dictionary attributes from xml parser.
     
     - parameter attributes: `Dictionary` attributes dictionary.
     
     - returns: `SKTileMapNode?`
     */
    public init?(attributes: [String: String]) {
        guard let width = attributes["width"] else { return nil }
        guard let height = attributes["height"] else { return nil }
        guard let tilewidth = attributes["tilewidth"] else { return nil }
        guard let tileheight = attributes["tileheight"] else { return nil }
        guard let orient = attributes["orientation"] else { return nil }
        
        // initialize tile size
        let tileSize = TileSize(width: CGFloat(Int(tilewidth)!), height: CGFloat(Int(tileheight)!))
        mapSize = MapSize(width: CGFloat(Int(width)!), height: CGFloat(Int(height)!), tileSize: tileSize)
        
        if let fileOrientation: TilemapOrientation = TilemapOrientation(rawValue: orient){
            self.orientation = fileOrientation
        }
        super.init()
    }
    
    public init(_ sizeX: Int, _ sizeY: Int, _ tileSizeX: Int, _ tileSizeY: Int) {
        mapSize = MapSize(width: CGFloat(sizeX), height: CGFloat(sizeY),
                          tileSize: TileSize(width: CGFloat(tileSizeX), height: CGFloat(tileSizeY)))
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Tilesets
    public func addTileset(tileset: SKTileset) {
        print("[SKTilemap]: adding tileset: \"\(tileset.name)\"")
        tileSets.insert(tileset)
    }
    
    /**
     Returns a named tileset from the tilesets set.
     
     - parameter name: `String` tileset to return.
     
     - returns: `SKTileset?` tileset object.
     */
    public func getTileset(name: String) -> SKTileset? {
        if let index = tileSets.indexOf( { $0.name == name } ) {
            let tileset = tileSets[index]
            return tileset
        }
        return nil
    }

    
    // MARK: - Layers
    /**
     Returns all layers, sorted by index.
     
     - returns: `[TiledLayerObject]` array of layers.
     */
    public func getLayers() -> [TiledLayerObject] {
        return layers.sort({$0.index < $1.index})
    }
    
    /**
     Returns an array of layer names.
     
     - returns: `[String]` layer names.
     */
    public func layerNames() -> [String] {
        return layers.flatMap { $0.name }
    }
    
    public func addLayer(layer: TiledLayerObject) {
        layer.index = layers.count > 0 ? lastIndex + 1 : 0

        // query the layer type
        var layerType = "tile"
        if let _ = layer as? SKObjectGroup { layerType = "object" }
        if let _ = layer as? SKImageLayer { layerType = "image" }
        
        print("[SKTilemap]: adding \(layerType) layer: \"\(layer.name!)\"...")
        layers.insert(layer)
        addChild(layer)
        positionLayer(layer)
        layer.zPosition = zDeltaForLayers * CGFloat(layer.index)
    }
    
    /**
     Returns a named tile layer from the layers set.
     
     - parameter name: `String` tile layer name.
     
     - returns: `TiledLayerObject?` layer object.
     */
    public func getLayer(named layerName: String) -> TiledLayerObject? {
        if let index = layers.indexOf( { $0.name == layerName } ) {
            let layer = layers[index]
            return layer
        }
        return nil
    }
    
    /**
     Returns a layer matching the given UUID.
     
     - parameter uuid: `String` tile layer UUID.
     
     - returns: `TiledLayerObject?` layer object.
     */
    public func getLayer(withID uuid: String) -> TiledLayerObject? {
        if let index = layers.indexOf( { $0.uuid == uuid } ) {
            let layer = layers[index]
            return layer
        }
        return nil
    }
    
    /**
     Returns a layer given the index (0 being the lowest).
     
     - parameter index: `Int` layer index.
     
     - returns: `TiledLayerObject?` layer object.
     */
    public func getLayer(atIndex index: Int) -> TiledLayerObject? {
        if let index = layers.indexOf( { $0.index == index } ) {
            let layer = layers[index]
            return layer
        }
        return nil
    }
    
    /**
     Isolate a named layer (hides other layers). Pass `nil`
     to show all layers.
     
     - parameter named: `String` layer name.
     */
    public func isolateLayer(named: String?=nil) {
        guard (named == nil) else {
            for layer in layers {
                layer.hidden = false
            }
            return
        }
        
        if let isolated = getLayer(named: named!) {
            print("[SKTilemap]: isolating layer: \"\(isolated.name!)\"")
            for layer in layers.filter({ $0 != isolated }) {
                layer.hidden = true
                if let layerName = layer.name {
                    print("  -> hiding layer: \"\(layerName)\"")
                }
            }
        }
    }
    
    /**
     Position child layers so in relation to the anchorpoint.
     
     - parameter layer: `TiledLayerObject` layer.
     */
    private func positionLayer(layer: TiledLayerObject) {
        var layerPosition = CGPointZero
        
        if orientation == .Orthogonal {
            layerPosition.x = -(renderSize.width * anchorPoint.x)
            layerPosition.y = (renderSize.height * anchorPoint.y)
        }
        
        layer.position = layerPosition
        layer.position.x += layer.offset.x
        layer.position.y -= layer.offset.y
    }
    
    // MARK: - Tiles
    public func tileAt(x: Int, _ y: Int, inLayer: String?) -> SKTile? {
        return nil
    }
    
    public func tileAt(coord: TileCoord, inLayer: String?) -> SKTile? {
        return nil
    }
    
    public func getTiles(ofType type: String) -> [SKTile] {
        var result: [SKTile] = []
        return result
    }
    
    // MARK: - Objects
    
    /**
     Return all of the current tile objects.
     
     - returns: `[SKTileObject]` array of objects.
     */
    public func getObjects() -> [SKTileObject] {
        var result: [SKTileObject] = []
        enumerateChildNodesWithName("//*") {
            node, stop in
            // do something with node or stop
            if let node = node as? SKTileObject {
                result.append(node)
            }
        }
        return result
    }
    
    /**
     Return objects matching a given type.
     
     - parameter named: `String` object name to query.
     
     - returns: `[SKTileObject]` array of objects.
     */
    public func getObjects(ofType type: String) -> [SKTileObject] {
        var result: [SKTileObject] = []
        enumerateChildNodesWithName("//*") {
            node, stop in
            // do something with node or stop
            if let node = node as? SKTileObject {
                if let objectType = node.type {
                    if objectType == type {
                        result.append(node)
                    }
                }
            }
        }
        return result
    }
    
    
    
    /**
     Return objects matching a given name.
     
     - parameter named: `String` object name to query.
     
     - returns: `[SKTileObject]` array of objects.
     */
    public func getObjects(named: String) -> [SKTileObject] {
        var result: [SKTileObject] = []
        enumerateChildNodesWithName("//*") {
            node, stop in
            // do something with node or stop
            if let node = node as? SKTileObject {
                if let objectName = node.name {
                    if objectName == named {
                
                        result.append(node)
                    }
                }
            }
        }
        return result
    }
    
    
    // MARK: - Data
    public func getTileData(gid: Int) -> SKTilesetData? {
        for tileset in tileSets {
            if let tileData = tileset.getTileData(gid) {
                return tileData
            }
        }
        return nil
    }
}


// MARK: - Extensions


extension MapSize: CustomStringConvertible, CustomDebugStringConvertible {
    
    public init(_ w: Int, _ h: Int, _ tw: Int, _ th: Int) {
        let tileSize = TileSize(width: CGFloat(tw), height: CGFloat(th))
        self.init(width: CGFloat(w), height: CGFloat(h), tileSize: tileSize)
    }
    
    /// Returns the map size as `CGSize`
    public var size: CGSize { return CGSizeMake(width, height) }
    
    /// Returns total tile `Int` count
    public var count: Int { return Int(width) * Int(height) }
    
    /// Returns the rendered `CGSize` of the map
    public var renderSize: CGSize { return CGSizeMake(width * tileSize.width, height * tileSize.height) }
    // Debugging
    public var description: String { return "\(Int(width)) x \(Int(height)) @ \(tileSize)" }
    public var debugDescription: String { return description }
    
    
    /**
     Returns a representative grid texture to be used as an overlay.
     
     - parameter scale: image scale (2 seems to work best for fine detail).
     
     - returns: `SKTexture` grid texture.
     */
    public func generateGridTexture(scale: CGFloat=2.0, gridColor: UIColor=UIColor.greenColor()) -> SKTexture {
        let image: UIImage = imageOfSize(self.renderSize, scale: scale) {
            
            for col in 0 ..< Int(self.width) {
                for row in (0 ..< Int(self.height)) {
                    
                    let tileWidth = self.tileSize.width
                    let tileHeight = self.tileSize.height
                    
                    let boxRect = CGRect(x: tileWidth * CGFloat(col), y: tileHeight * CGFloat(row), width: tileWidth, height: tileHeight)
                    
                    let context = UIGraphicsGetCurrentContext()
                    let boxPath = UIBezierPath(rect: boxRect)
                    
                    gridColor.setStroke()
                    boxPath.lineWidth = 1
                    CGContextSaveGState(context)
                    CGContextSetLineDash(context, 4, [4, 4], 2)
                    boxPath.stroke()
                    CGContextRestoreGState(context)
                }
            }
        }
        
        let result = SKTexture(CGImage: image.CGImage!)
        //result.filteringMode = .Nearest
        return result
    }
}


extension TileSize: CustomStringConvertible, CustomDebugStringConvertible {
    
    /**
     Initialize `TileSize` with two integers.
     
     - parameter x: `Int` tile width.
     - parameter y: `Int` tile height.
     
     - returns: `TileSize` tile size.
     */
    public init(_ x: Int, _ y: Int){
        self.init(width: CGFloat(x), height: CGFloat(y))
    }
    
    /**
     Initialize `TileSize` a single integer representing w/h values.
     
     - parameter tile: `Int` tile height & width.
     
     - returns: `TileSize` tile size.
     */
    public init(_ tile: Int){
        self.init(width: CGFloat(tile), height: CGFloat(tile))
    }
    
    /**
     Initialize `TileSize` a single CGFloat representing w/h values.
     
     - parameter tile: `CGFloat` tile height & width.
    
     - returns: `TileSize` tile size.
     */
    public init(_ tile: CGFloat){
        self.init(width: tile, height: tile)
    }
    
    /// Returns the tile size as `CGSize`
    public var size: CGSize { return CGSizeMake(width, height) }
    // Debugging
    public var description: String { return "\(Int(width)) x \(Int(height))" }
    public var debugDescription: String { return description }
}


public extension TileCoord {
    
    /**
     Initialize `TileCoord` with two integers.
     
     - parameter x: `Int` x-coordinate.
     - parameter y: `Int` y-coordinate.
     
     - returns: `TileCoord` coordinate.
     */
    public init(_ x: Int, _ y: Int){
        self.init(Int32(x), Int32(y))
    }
    
    /// Convert the coordinate to vector2.
    public var vec2: int2 {
        return int2(x, y)
    }
}


public extension SKTilemap {

    /**
     Calculate the distance from the node's origin
     */
    public func distanceFromOrigin(pos: CGPoint) -> CGVector {
        let dx = (pos.x - center.x)
        let dy = (pos.y - center.y)
        return CGVectorMake(dx, dy)
    }
    
    override public var description: String {
        var tilemapName = "(null)"
        if let name = name {
            tilemapName = "\"\(name)\""
        }
        return "Tilemap: \(tilemapName), \(mapSize) \(renderSize)"
    }
    
    override public var debugDescription: String { return description }
}
