"use client";

import { useEffect, useState } from "react";
import SmartLink from "./SmartLink";

export interface BannerMessage {
  text: string;
  link?: string;
}

// Messaggi dell'avviso che si alternano, con dissolvenza o salendo dal basso.
export default function BannerRotator({
  messages,
  effect,
  interval,
}: {
  messages: BannerMessage[];
  effect: "fade" | "slide";
  interval: number;
}) {
  const [index, setIndex] = useState(0);

  useEffect(() => {
    if (messages.length < 2) return;
    const timer = setInterval(() => setIndex((i) => (i + 1) % messages.length), interval);
    return () => clearInterval(timer);
  }, [messages.length, interval]);

  const m = messages[index] ?? messages[0];
  const animation = effect === "fade" ? "banner-fade" : "banner-up";
  return (
    <div className="overflow-hidden" aria-live="polite">
      <div key={index} className={animation}>
        {m.link ? (
          <SmartLink href={m.link} className="hover:underline">
            {m.text}
          </SmartLink>
        ) : (
          m.text
        )}
      </div>
    </div>
  );
}
