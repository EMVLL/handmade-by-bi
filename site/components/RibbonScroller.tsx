"use client";

import { useEffect, useRef, type ReactNode } from "react";

const SPEED = 35; // pixel al secondo
const RESUME_AFTER = 2500; // ms dopo l'ultimo tocco

// Nastro infinito: scorre da solo, ma si può trascinare avanti e indietro
// (dito sul telefono, mouse o rotella sul computer). Mentre lo si tocca si ferma.
// Il contenuto deve essere ripetuto due volte (due metà uguali).
export default function RibbonScroller({ children }: { children: ReactNode }) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

    let pos = 1;
    let paused = false;
    let hovering = false;
    let resumeTimer: ReturnType<typeof setTimeout> | undefined;
    let last = performance.now();
    let frame = 0;

    // Arrivati a metà si torna all'inizio (e viceversa): il giro non finisce mai.
    const wrap = () => {
      const half = el.scrollWidth / 2;
      if (half <= el.clientWidth) return;
      if (el.scrollLeft >= half) el.scrollLeft -= half;
      else if (el.scrollLeft <= 0) el.scrollLeft += half;
      pos = el.scrollLeft;
    };

    const pause = () => {
      paused = true;
      if (resumeTimer) clearTimeout(resumeTimer);
    };
    const resumeLater = () => {
      if (resumeTimer) clearTimeout(resumeTimer);
      resumeTimer = setTimeout(() => {
        if (!hovering) {
          pos = el.scrollLeft;
          paused = false;
        }
      }, RESUME_AFTER);
    };

    const tick = (now: number) => {
      const dt = Math.min((now - last) / 1000, 0.1);
      last = now;
      if (!paused && !reduce) {
        pos += SPEED * dt;
        el.scrollLeft = pos;
        wrap();
      }
      frame = requestAnimationFrame(tick);
    };
    el.scrollLeft = pos;
    frame = requestAnimationFrame(tick);

    // Trascinamento con il mouse (sul telefono scorre già da solo col dito)
    let dragging = false;
    let startX = 0;
    let startScroll = 0;
    const onPointerDown = (e: PointerEvent) => {
      pause();
      if (e.pointerType !== "mouse") return;
      dragging = true;
      startX = e.clientX;
      startScroll = el.scrollLeft;
      el.dataset.dragMoved = "";
    };
    const onPointerMove = (e: PointerEvent) => {
      if (!dragging) return;
      if (e.buttons === 0) return onPointerUp(); // tasto già rilasciato fuori dalla pagina
      const dx = e.clientX - startX;
      if (Math.abs(dx) > 5) el.dataset.dragMoved = "1"; // è un trascinamento, non un clic
      // Posizione "a giro": si può trascinare all'infinito in entrambe le direzioni
      const half = el.scrollWidth / 2;
      let target = startScroll - dx;
      if (half > el.clientWidth) {
        target = ((target % half) + half) % half;
        if (target < 1) target += half;
      }
      el.scrollLeft = target;
      pos = el.scrollLeft;
    };
    const onPointerUp = () => {
      dragging = false;
      resumeLater();
      // il clic arriva subito dopo: lo lascio bloccare, poi azzero
      setTimeout(() => (el.dataset.dragMoved = ""), 0);
    };
    const onClickCapture = (e: MouseEvent) => {
      if (el.dataset.dragMoved === "1") {
        e.preventDefault();
        e.stopPropagation();
      }
    };
    const onScroll = () => {
      if (paused) wrap();
    };
    // Il browser non deve "trascinare via" foto e link: si trascina il nastro
    const onDragStart = (e: DragEvent) => e.preventDefault();
    const onTouchStart = () => pause();
    const onTouchEnd = () => resumeLater();
    const onWheel = () => {
      pause();
      resumeLater();
    };
    const onEnter = () => {
      hovering = true;
      pause();
    };
    const onLeave = () => {
      hovering = false;
      resumeLater();
    };

    el.addEventListener("pointerdown", onPointerDown);
    el.addEventListener("dragstart", onDragStart);
    window.addEventListener("pointermove", onPointerMove);
    window.addEventListener("pointerup", onPointerUp);
    el.addEventListener("click", onClickCapture, true);
    el.addEventListener("scroll", onScroll, { passive: true });
    el.addEventListener("touchstart", onTouchStart, { passive: true });
    el.addEventListener("touchend", onTouchEnd, { passive: true });
    el.addEventListener("wheel", onWheel, { passive: true });
    el.addEventListener("mouseenter", onEnter);
    el.addEventListener("mouseleave", onLeave);
    return () => {
      cancelAnimationFrame(frame);
      if (resumeTimer) clearTimeout(resumeTimer);
      el.removeEventListener("pointerdown", onPointerDown);
      el.removeEventListener("dragstart", onDragStart);
      window.removeEventListener("pointermove", onPointerMove);
      window.removeEventListener("pointerup", onPointerUp);
      el.removeEventListener("click", onClickCapture, true);
      el.removeEventListener("scroll", onScroll);
      el.removeEventListener("touchstart", onTouchStart);
      el.removeEventListener("touchend", onTouchEnd);
      el.removeEventListener("wheel", onWheel);
      el.removeEventListener("mouseenter", onEnter);
      el.removeEventListener("mouseleave", onLeave);
    };
  }, []);

  return (
    <div ref={ref} className="ribbon ribbon-scroll -mx-5 select-none">
      <div className="flex w-max">{children}</div>
    </div>
  );
}
