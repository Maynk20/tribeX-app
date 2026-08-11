import { Link } from "@tanstack/react-router";
import { Compass, PlusCircle, MessageCircle, User, type LucideIcon } from "lucide-react";
import type { ReactNode } from "react";

const linkClass =
  "group relative flex flex-1 flex-col items-center gap-1 rounded-2xl px-2 py-2 text-[11px] font-medium text-muted-foreground transition-all duration-150 active:scale-95 data-[status=active]:text-primary";

function TabInner({ Icon, label }: { Icon: LucideIcon; label: string }): ReactNode {
  return (
    <>
      <Icon className="h-5 w-5 transition-transform duration-150 group-data-[status=active]:scale-110" strokeWidth={2.2} />
      <span className="tracking-wide">{label}</span>
      <span className="absolute -top-[9px] left-1/2 h-1 w-8 -translate-x-1/2 rounded-full bg-primary opacity-0 transition-opacity duration-200 group-data-[status=active]:opacity-100" />
    </>
  );
}

export function BottomNav() {
  return (
    <nav className="fixed bottom-0 left-1/2 z-40 w-full max-w-md -translate-x-1/2 border-t border-border/60 bg-background/85 backdrop-blur-xl">
      <ul className="grid grid-cols-4 px-2 pb-[env(safe-area-inset-bottom)] pt-2">
        <li className="flex">
          <Link to="/" activeOptions={{ exact: true }} preload="intent" className={linkClass}>
            <TabInner Icon={Compass} label="Explore" />
          </Link>
        </li>
        <li className="flex">
          <Link to="/create" activeOptions={{ exact: true }} preload="intent" className={linkClass}>
            <TabInner Icon={PlusCircle} label="Create" />
          </Link>
        </li>
        <li className="flex">
          <Link to="/messages" activeOptions={{ exact: true }} preload="intent" className={linkClass}>
            <TabInner Icon={MessageCircle} label="Messages" />
          </Link>
        </li>
        <li className="flex">
          <Link to="/profile" activeOptions={{ exact: true }} preload="intent" className={linkClass}>
            <TabInner Icon={User} label="Profile" />
          </Link>
        </li>
      </ul>
    </nav>
  );
}