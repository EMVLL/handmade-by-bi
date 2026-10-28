import Link from "next/link";
import type { ReactNode } from "react";
import { isInternal } from "@/lib/format";

// Link interno (navigazione veloce) o esterno (nuova scheda), in base all'indirizzo.
export default function SmartLink({
  href,
  className,
  children,
}: {
  href: string;
  className?: string;
  children: ReactNode;
}) {
  if (isInternal(href)) {
    return (
      <Link href={href} className={className}>
        {children}
      </Link>
    );
  }
  return (
    <a href={href} className={className} target="_blank" rel="noopener noreferrer">
      {children}
    </a>
  );
}
