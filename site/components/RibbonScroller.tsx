"use client";

import { useEffect, useRef, type ReactNode } from "react";

const SPEED = 35; // pixel al secondo
const RESUME_AFTER = 2500; // ms da quando il nastro si è fermato del tutto
const SETTLE = 150; // ms senza movimento = lo scorrimento col dito è finito

// Nastro infinito: scorre da solo, ma si può trascinare avanti e indietro
// (dito sul telefono, mouse o rotella sul computer). Mentre lo si tocca si ferma.
// Il contenuto deve essere ripetuto TRE volte (tre giri uguali): si sta sempre nel
// giro centrale e, quando ci si sposta in uno laterale, si torna in quello centrale
// nel punto identico, senza che si veda.
export default function RibbonScroller({ children }: { children: ReactNode }) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

    const round = () => el.scrollWidth / 3;
    let pos = 0; // posizione con i decimali (scrollLeft su alcuni telefoni è intero)
    let paused = false;
    let hovering = false; // solo mouse: sul telefono il "passaggio sopra" non esiste
    let touching = false;
    let lastUserScroll = 0; // ultimo movimento non fatto dallo scorrimento automatico
    let resumeTimer: ReturnType<typeof setTimeout> | undefined;
    let settleTimer: ReturnType<typeof setTimeout> | undefined;
    let last = performance.now();
    let frame = 0;

    // Riporta nel giro centrale. Non va fatto mentre il dito trascina o il nastro
    // sta ancora correndo per l'inerzia: il telefono interromperebbe il gesto.
    const recenter = () => {
      const r = round();
      if (r <= el.clientWidth) return;
      let x = el.scrollLeft;
      if (x < r) x += r;
      else if (x >= 2 * r) x -= r;
      else return;
      el.scrollLeft = x;
      pos = x;
    };

    const pause = () => {
      paused = true;
      if (resumeTimer) clearTimeout(resumeTimer);
    };
    const resumeLater = () => {
      if (resumeTimer) clearTimeout(resumeTimer);
      resumeTimer = setTimeout(() => {
        if (hovering || touching) return;
        recenter();
        pos = el.scrollLeft;
        paused = false;
      }, RESUME_AFTER);
    };

    const tick = (now: number) => {
      const dt = Math.min((now - last) / 1000, 0.1);
      last = now;
      if (!paused && !reduce) {
        pos += SPEED * dt;
        const r = round();
        if (r > el.clientWidth && pos >= 2 * r) pos -= r;
        el.scrollLeft = pos;
      }
      frame = requestAnimationFrame(tick);
    };
    // Partenza dall'inizio del giro centrale
    pos = round();
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
      // Sempre dentro il giro centrale: si trascina all'infinito in entrambe le direzioni
      const r = round();
      let target = startScroll - dx;
      if (r > el.clientWidth) target = r + ((((target - r) % r) + r) % r);
      el.scrollLeft = target;
      pos = el.scrollLeft;
    };
    const onPointerUp = () => {
      if (!dragging) return;
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
    // Dopo un trascinamento col dito (o la rotella) si torna al centro solo a nastro fermo.
    // Su iPhone l'inerzia continua a far scorrere il nastro per qualche secondo dopo che il
    // dito si è alzato: finché arrivano movimenti, la ripartenza automatica viene rimandata,
    // altrimenti la ripartenza e l'inerzia si contendono il nastro (sobbalzi e foto sovrapposte).
    const onScroll = () => {
      if (!paused || dragging) return;
      lastUserScroll = performance.now();
      if (settleTimer) clearTimeout(settleTimer);
      settleTimer = setTimeout(() => {
        if (!touching) recenter();
      }, SETTLE);
      if (!touching) resumeLater();
    };
    // Il browser non deve "trascinare via" foto e link: si trascina il nastro
    const onDragStart = (e: DragEvent) => e.preventDefault();
    const onTouchStart = () => {
      const wasRunning = !paused; // scorreva da solo: nessuna inerzia in corso
      touching = true;
      pause();
      // A nastro fermo si torna subito al centro, così anche tante strisciate di fila
      // non arrivano mai al bordo. Se invece sta ancora scorrendo per l'inerzia non si
      // tocca: su iPhone spostarlo in quel momento lo fa sobbalzare.
      if (wasRunning || performance.now() - lastUserScroll > SETTLE) {
        if (settleTimer) clearTimeout(settleTimer);
        recenter();
      }
    };
    const onTouchEnd = () => {
      touching = false;
      onScroll(); // se il nastro era già fermo, torna subito al centro
      resumeLater();
    };
    const onWheel = () => {
      pause();
      resumeLater();
    };
    const onEnter = (e: PointerEvent) => {
      if (e.pointerType !== "mouse") return;
      hovering = true;
      pause();
    };
    const onLeave = (e: PointerEvent) => {
      if (e.pointerType !== "mouse") return;
      hovering = false;
      resumeLater();
    };

    el.addEventListener("pointerdown", onPointerDown);
    el.addEventListener("dragstart", onDragStart);
    window.addEventListener("pointermove", onPointerMove);
    window.addEventListener("pointerup", onPointerUp);
    window.addEventListener("pointercancel", onPointerUp);
    el.addEventListener("click", onClickCapture, true);
    el.addEventListener("scroll", onScroll, { passive: true });
    el.addEventListener("touchstart", onTouchStart, { passive: true });
    el.addEventListener("touchend", onTouchEnd, { passive: true });
    el.addEventListener("touchcancel", onTouchEnd, { passive: true });
    el.addEventListener("wheel", onWheel, { passive: true });
    el.addEventListener("pointerenter", onEnter);
    el.addEventListener("pointerleave", onLeave);
    return () => {
      cancelAnimationFrame(frame);
      if (resumeTimer) clearTimeout(resumeTimer);
      if (settleTimer) clearTimeout(settleTimer);
      el.removeEventListener("pointerdown", onPointerDown);
      el.removeEventListener("dragstart", onDragStart);
      window.removeEventListener("pointermove", onPointerMove);
      window.removeEventListener("pointerup", onPointerUp);
      window.removeEventListener("pointercancel", onPointerUp);
      el.removeEventListener("click", onClickCapture, true);
      el.removeEventListener("scroll", onScroll);
      el.removeEventListener("touchstart", onTouchStart);
      el.removeEventListener("touchend", onTouchEnd);
      el.removeEventListener("touchcancel", onTouchEnd);
      el.removeEventListener("wheel", onWheel);
      el.removeEventListener("pointerenter", onEnter);
      el.removeEventListener("pointerleave", onLeave);
    };
  }, []);

  return (
    <div ref={ref} className="ribbon ribbon-scroll -mx-5 select-none">
      <div className="flex w-max">{children}</div>
    </div>
  );
}
