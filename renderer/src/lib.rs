use std::{ffi::{c_char, CStr}, fs, iter::Filter};

use cslice::CSlice;
use ril::{encodings::png::FilterType, fill::SolidFill, filter::{Brightness, Mask}, Ellipse, Image, ImageFormat, ImageSequence, Rgba};

#[repr(C)]
pub struct Vec2f {
    pub x: f32,
    pub y: f32,
}

#[repr(C)]
pub struct PhysicsParticle {
    pub mass: f32,
    pub velocity: Vec2f,
    pub position: Vec2f,
}

#[repr(C)]
pub struct EnvironmentBounds {
    pub top_left: Vec2f,
    pub size: Vec2f,
}

const PARTICLE_TEXTURE_DATA: &[u8] = include_bytes!("particle.png");

#[no_mangle]
pub extern "C" fn cache_frame(dir: *const c_char, particles: CSlice<PhysicsParticle>, bounds: EnvironmentBounds) {
    let mut image: Image<Rgba> = Image::new(bounds.size.x as u32, bounds.size.y as u32, Rgba::black());
    let particle_texture: Image<Rgba> = Image::from_bytes(ImageFormat::Png, PARTICLE_TEXTURE_DATA).unwrap();

    for particle in particles.as_ref() {
        let (left, top) = (
            particle.position.x - particle_texture.width() as f32 / 2.,
            particle.position.y - particle_texture.height() as f32 / 2.
        );

        image.paste_with_mask(left as u32, top as u32, &particle_texture, &particle_texture.clone().into());
    }

    let path = unsafe { CStr::from_ptr(dir).to_str() }.unwrap();
    image.save(ImageFormat::Png, path).unwrap();
}

#[no_mangle]
pub extern "C" fn build_gif(_framerate: u32, frames_dir: *const c_char, output_dir: *const c_char) {
    let mut gif: ImageSequence<Rgba> = ImageSequence::new();

    let dir = fs::read_dir(unsafe { CStr::from_ptr(frames_dir) }.to_str().unwrap()).unwrap();
    for file in dir {
        if let Ok(file) = file {
            let img = Image::open(file.path()).unwrap();
            gif.push_frame(img.into());
        }
    }

    gif.save(ImageFormat::Gif, unsafe { CStr::from_ptr(output_dir) }.to_str().unwrap()).unwrap();
}