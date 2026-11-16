"use client";

import Image from "next/image";
import { useState } from "react";

export interface GalleryImage {
  src: string;
  /** Centro scelto per i ritagli (miniature); undefined = centro della foto */
  position?: string;
}

// Foto del pezzo. Quella grande si vede SEMPRE intera (niente ritagli): ai lati, se la foto
// è più stretta o più bassa del riquadro, c'è la stessa foto sfocata. Le miniature sono
// ritagliate attorno al centro scelto da Benedetta.
export default function ProductGallery({ images, alt }: { images: GalleryImage[]; alt: string }) {
  const [current, setCurrent] = useState(0);

  if (!images.length) {
    return (
      <div className="flex aspect-square items-center justify-center rounded-site bg-foreground/5 text-sm opacity-50">
        Foto in arrivo
      </div>
    );
  }

  const shown = images[Math.min(current, images.length - 1)];

  return (
    <div className="min-w-0 space-y-3">
      <div className="relative aspect-square overflow-hidden rounded-site bg-foreground/5">
        {/* Fondo: la stessa foto in piccolo (leggera da scaricare), sfocata e ingrandita */}
        <Image
          src={shown.src}
          alt=""
          aria-hidden
          fill
          sizes="96px"
          className="scale-125 object-cover opacity-80 blur-2xl saturate-[.9]"
        />
        <Image
          key={shown.src}
          src={shown.src}
          alt={alt}
          fill
          sizes="(min-width: 768px) 50vw, 100vw"
          className="object-contain"
          loading="eager"
          fetchPriority="high"
        />
      </div>
      {images.length > 1 && (
        <div className="flex gap-2 overflow-x-auto">
          {images.map((img, i) => (
            <button
              key={img.src}
              type="button"
              onClick={() => setCurrent(i)}
              className={`relative h-16 w-16 shrink-0 overflow-hidden rounded-site border-2 ${
                i === current ? "border-primary" : "border-transparent"
              }`}
              aria-label={`Foto ${i + 1}`}
            >
              <Image src={img.src} alt="" fill sizes="64px" className="object-cover" style={{ objectPosition: img.position }} />
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
