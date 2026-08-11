import { useEffect, useState } from "react";
import { Sparkles } from "lucide-react";
import { cn } from "@/lib/utils";

interface WelcomeSplashProps {
  profile?: {
    full_name?: string | null;
    username?: string | null;
  } | null;
  onComplete: () => void;
}

export function WelcomeSplash({ profile, onComplete }: WelcomeSplashProps) {
  const [isFadingOut, setIsFadingOut] = useState(false);

  useEffect(() => {
    // Start fading out after 2.2 seconds
    const fadeTimer = setTimeout(() => {
      setIsFadingOut(true);
    }, 2200);

    // Call onComplete after transition completes (2.7 seconds total)
    const completeTimer = setTimeout(() => {
      onComplete();
    }, 2700);

    return () => {
      clearTimeout(fadeTimer);
      clearTimeout(completeTimer);
    };
  }, [onComplete]);

  const handleSkip = () => {
    setIsFadingOut(true);
    setTimeout(() => {
      onComplete();
    }, 400); // match transition duration
  };

  const displayName = profile?.full_name || profile?.username;

  return (
    <div
      onClick={handleSkip}
      className={cn(
        "fixed inset-0 z-[999999] flex flex-col items-center justify-center bg-background text-foreground select-none transition-all duration-500 ease-out",
        isFadingOut ? "opacity-0 scale-105 pointer-events-none" : "opacity-100 scale-100"
      )}
    >
      {/* Background Radial Glow */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[340px] h-[340px] rounded-full bg-primary/10 blur-[100px] pointer-events-none" />

      {/* Floating Animated Logo Container */}
      <div className="relative mb-8 flex flex-col items-center">
        {/* Glow Ring behind the logo */}
        <div className="absolute inset-0 rounded-[28px] bg-primary/15 blur-2xl animate-pulse" />
        
        <div className="relative animate-welcome-zoom">
          <div className="animate-welcome-float">
            <img
              src="/favicon.png"
              alt="tribeX logo"
              className="h-28 w-28 rounded-[28px] object-contain shadow-xl border border-border/40 bg-card"
            />
          </div>
        </div>
      </div>

      {/* Animated Text Container */}
      <div className="text-center px-6 z-10 animate-welcome-text flex flex-col items-center">
        <span className="text-[11px] font-bold uppercase tracking-[0.25em] text-muted-foreground/80 mb-2">
          welcome to
        </span>
        
        <h1 className="text-4xl font-black tracking-tight text-foreground mb-4">
          <span className="text-primary">tribe</span>X
        </h1>

        <div className="h-6 flex items-center justify-center">
          {displayName ? (
            <div className="flex items-center gap-1.5 text-sm font-medium text-muted-foreground animate-[fade-in_0.4s_ease-out_both]">
              <Sparkles className="h-4 w-4 text-primary animate-pulse" />
              <span>
                Welcome back, <span className="text-primary font-semibold">{displayName}</span>!
              </span>
            </div>
          ) : (
            <p className="text-sm font-medium text-muted-foreground">
              Find your crew, join the plan
            </p>
          )}
        </div>
      </div>

      {/* Skip indicator at the bottom */}
      <div className="absolute bottom-10 left-0 right-0 text-center pointer-events-none animate-pulse">
        <span className="text-[10px] uppercase tracking-widest text-muted-foreground/60 font-semibold">
          Tap anywhere to enter
        </span>
      </div>
    </div>
  );
}
