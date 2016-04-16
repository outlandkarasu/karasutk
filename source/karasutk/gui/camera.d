module karasutk.gui.camera;

import gl3n.linalg;
import gl3n.math;

@safe:

/// camera position and rotation structure.
struct Camera {

    ref Camera rotateX(T)(T x) {
        rotation_.x += x;
        return this;
    }

    ref Camera rotateY(T)(T y) {
        rotation_.y += y;
        return this;
    }

    ref Camera rotateZ(T)(T z) {
        rotation_.z += z;
        return this;
    }

    ref Camera moveX(T)(T x) {
        position_.x += x;
        return this;
    }

    ref Camera moveY(T)(T y) {
        position_.y += y;
        return this;
    }

    ref Camera moveZ(T)(T z) {
        position_.z += z;
        return this;
    }

    ref Camera move(T)(T x, T y, T z) {
        return move(Vector!(T, 3)(x, y, z));
    }

    ref Camera move(T)(auto ref const Vector!(T, 3) distance) {
        position_ += distance;
        return this;
    }

    ref Camera orthogonal(float l, float r, float b, float t, float n, float f) {
        projection_ = mat4.orthographic(l, r, b, t, n, f);
        return this;
    }

    ref Camera perspective(float w, float h, float fov, float n, float f) {
        projection_ = mat4.perspective(w, h, fov, n, f);
        return this;
    }

    @property const nothrow pure @nogc {

        /// return projection matrix.
        mat4 projection() {return projection_;}

        /// return view matrix.
        mat4 view() {
            return mat4.translation(-position_.x, -position_.y, -position_.z)
                .rotatex(rotation_.x)
                .rotatey(rotation_.y)
                .rotatez(rotation_.z);
        }
    }

private:
    alias vec3r = Vector!(real, 3);

    vec3 position_ = vec3(0.0f, 0.0f, 0.0f);
    vec3r rotation_ = vec3r(0.0L, 0.0L, 0.0L);
    mat4 projection_ = mat4.identity;
}

