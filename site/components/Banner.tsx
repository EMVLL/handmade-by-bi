import { Fragment } from "react";
import BannerRotator, { type BannerMessage } from "./BannerRotator";
import SmartLink from "./SmartLink";

const STYLE: Record<string, string> = {
  info: "bg-foreground/5",
  highlight: "bg-primary text-white",
  sale: "bg-accent text-white",
};

// Secondi per far passare tutto il nastro, e millisecondi tra un messaggio e l'altro
const MARQUEE_SECONDS = { slow: 9, normal: 6, fast: 4 } as const;
const ROTATE_MS = { slow: 6000, normal: 4000, fast: 2500 } as const;

type Speed = keyof typeof ROTATE_MS;

function Message({ m }: { m: BannerMessage }) {
  return m.link ? (
    <SmartLink href={m.link} className="hover:underline">
      {m.text}
    </SmartLink>
  ) : (
    <>{m.text}</>
  );
}

// Avviso in una striscia colorata: fisso, che scorre, o che cambia messaggio.
export default function Banner({
  messages,
  effect,
  speed,
  style,
}: {
  messages: BannerMessage[];
  effect: string;
  speed: string;
  style: string;
}) {
  if (!messages.length) return null;
  const pace: Speed = speed === "slow" || speed === "fast" ? speed : "normal";
  const cls = `px-5 py-3 text-center text-sm font-semibold ${STYLE[style] ?? STYLE.info}`;

  if (effect === "marquee") {
    // Ripeto i messaggi per riempire la striscia, poi raddoppio per un giro senza scatti
    const half: BannerMessage[] = [];
    while (half.length < 6) half.push(...messages);
    const seconds = MARQUEE_SECONDS[pace] * half.length;
    return (
      <div className={`marquee overflow-hidden px-0 ${cls}`}>
        <div className="marquee-track flex w-max" style={{ animationDuration: `${seconds}s` }}>
          {[...half, ...half].map((m, i) => (
            <span key={i} className="whitespace-nowrap px-8" aria-hidden={i >= half.length || undefined}>
              <Message m={m} />
            </span>
          ))}
        </div>
      </div>
    );
  }

  if ((effect === "fade" || effect === "slide") && messages.length > 1) {
    return (
      <div className={cls}>
        <BannerRotator messages={messages} effect={effect} interval={ROTATE_MS[pace]} />
      </div>
    );
  }

  // Fisso: tutti i messaggi, uno dopo l'altro
  return (
    <div className={cls}>
      {messages.map((m, i) => (
        <Fragment key={i}>
          {i > 0 && <span className="mx-3 opacity-60">·</span>}
          <Message m={m} />
        </Fragment>
      ))}
    </div>
  );
}
