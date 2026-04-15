//
//  math.swift
//  metal-stuff
//
//  Created by matty on 4/13/26.
//

import simd
import CoreGraphics

public typealias vec2 = SIMD2<Float>
public typealias vec3 = SIMD3<Float>
public typealias vec4 = SIMD4<Float>
public typealias mat3 = float3x3
public typealias mat4 = float4x4

public enum Math {
    public static func perspective(fovyRadians: Float, aspect: Float, nearZ: Float, farZ: Float) -> float4x4 {
        let ys = 1 / tan(fovyRadians * 0.5)
        let xs = ys / aspect
        let zs = farZ / (nearZ - farZ)
        
        return float4x4(rows: [[xs, 0, 0, 0],
                               [0, ys, 0, 0],
                               [0, 0, zs, nearZ * zs],
                               [0, 0, -1, 0]])
    }
    
    public static func ortho(left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float) -> float4x4 {
        let X = SIMD4<Float>(2 / (right - left), 0, 0, 0)
        let Y = SIMD4<Float>(0, 2 / (top - bottom), 0, 0)
        let Z = SIMD4<Float>(0, 0, 1 / (far - near), 0)
        let W = SIMD4<Float>(
            -((left + right) / (left - right)),
             -((top + bottom) / (bottom - top)),
             -(near / (near - far)),
             1)
        return float4x4(columns:(X, Y, Z, W))
    }
    
    public static func lookAt(position: SIMD3<Float>, target: SIMD3<Float>, up: SIMD3<Float>) -> float4x4 {
        let zaxis = normalize(position - target)
        let xaxis = normalize(cross(normalize(up), zaxis))
        let yaxis = cross(zaxis, xaxis)
        
        let t: SIMD3<Float> = [-simd_dot(xaxis, position), -simd_dot(yaxis, position), -simd_dot(zaxis, position)]
        
        return float4x4(rows: [[xaxis.x, xaxis.y, xaxis.z, t.x],
                               [yaxis.x, yaxis.y, yaxis.z, t.y],
                               [zaxis.x, zaxis.y, zaxis.z, t.z],
                               [0, 0, 0, 1]])
    }
    
    public static func radians(from degrees: Float) -> Float {
        return degrees * .pi / 180
    }
    
    public static func translation(vector: SIMD3<Float>) -> float4x4 {
        return float4x4(rows: [[1, 0, 0, vector.x],
                               [0, 1, 0, vector.y],
                               [0, 0, 1, vector.z],
                               [0, 0, 0, 1]])
    }
    
    public static func rotate(rotation: SIMD3<Float>) -> float4x4 {
        let c = cos(rotation * 0.5);
        let s = sin(rotation * 0.5);
        
        var quat = simd_float4(repeating: 1.0);
        
        quat.w = c.x * c.y * c.z + s.x * s.y * s.z;
        quat.x = s.x * c.y * c.z - c.x * s.y * s.z;
        quat.y = c.x * s.y * c.z + s.x * c.y * s.z;
        quat.z = c.x * c.y * s.z - s.x * s.y * c.z;
        
        var rotationMat = matrix_identity_float4x4;
        let qxx = quat.x * quat.x;
        let qyy = quat.y * quat.y;
        let qzz = quat.z * quat.z;
        let qxz = quat.x * quat.z;
        let qxy = quat.x * quat.y;
        let qyz = quat.y * quat.z;
        let qwx = quat.w * quat.x;
        let qwy = quat.w * quat.y;
        let qwz = quat.w * quat.z;
        
        rotationMat[0][0] = 1.0 - 2.0 * (qyy + qzz);
        rotationMat[0][1] = 2.0 * (qxy + qwz);
        rotationMat[0][2] = 2.0 * (qxz - qwy);
        
        rotationMat[1][0] = 2.0 * (qxy - qwz);
        rotationMat[1][1] = 1.0 - 2.0 * (qxx + qzz);
        rotationMat[1][2] = 2.0 * (qyz + qwx);
        
        rotationMat[2][0] = 2.0 * (qxz + qwy);
        rotationMat[2][1] = 2.0 * (qyz - qwx);
        rotationMat[2][2] = 1.0 - 2.0 * (qxx + qyy);
        
        return rotationMat
    }
    
    public static func scale(vector: SIMD3<Float>) -> float4x4 {
        return float4x4(rows: [[vector.x, 0, 0, 0],
                               [0, vector.y, 0, 0],
                               [0, 0, vector.z, 0],
                               [0, 0, 0,        1]])
    }
    
    public static func scale(scale: Float) -> float4x4 {
        return Self.scale(vector: [scale, scale, scale])
    }
    
    public static func identity() -> float4x4 {
        matrix_identity_float4x4
    }
}

public extension float4x4 {
    var upperLeft: float3x3 {
        let x = columns.0.xyz
        let y = columns.1.xyz
        let z = columns.2.xyz
        return float3x3(columns: (x, y, z))
    }
}

public extension SIMD4<Float> {
    var xyz: SIMD3<Float> {
        get {
            SIMD3<Float>(x, y, z)
        }
        set {
            x = newValue.x
            y = newValue.y
            z = newValue.z
        }
    }
    
    // convert from double4
    init(_ d: SIMD4<Double>) {
        self.init()
        self = [Float(d.x), Float(d.y), Float(d.z), Float(d.w)]
    }
}

public extension Float {
    var radians: Float {
        Math.radians(from: self)
    }
}

public extension Double {
    var radians: Float {
        Math.radians(from: Float(self))
    }
}

public extension float4x4 {
    func translate(vector: vec3) -> float4x4 {
        self * Math.translation(vector: vector)
    }
    
    func rotate(vector: vec3) -> float4x4 {
        self * Math.rotate(rotation: vector)
    }
    
    func scale(vector: vec3) -> float4x4 {
        self * Math.scale(vector: vector)
    }
    
    func scale(scale: Float) -> float4x4 {
        self * Math.scale(scale: scale)
    }
}
