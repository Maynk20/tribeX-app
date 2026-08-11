import { useState } from "react";
import { Check, ChevronsUpDown, MapPin, Search } from "lucide-react";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Command, CommandEmpty, CommandGroup, CommandInput, CommandItem, CommandList } from "@/components/ui/command";
import { INDIA_CITIES } from "@/lib/india-cities";
import { cn } from "@/lib/utils";

type Props = {
  value: string;
  onChange: (city: string) => void;
  className?: string;
  variant?: "chip" | "input";
  placeholder?: string;
};

export function CityCombobox({ value, onChange, className, variant = "chip", placeholder = "Select city" }: Props) {
  const [open, setOpen] = useState(false);

  const trigger =
    variant === "chip" ? (
      <button
        type="button"
        className={cn(
          "inline-flex items-center gap-1 text-xs font-medium uppercase tracking-[0.18em] text-muted-foreground transition hover:text-primary",
          className,
        )}
        aria-label="Change city"
      >
        <MapPin className="h-3 w-3" />
        <span className="normal-case tracking-normal">{value || placeholder}</span>
        <ChevronsUpDown className="h-3 w-3 opacity-60" />
      </button>
    ) : (
      <button
        type="button"
        className={cn(
          "flex w-full items-center justify-between gap-2 rounded-2xl border border-border/60 bg-card px-4 py-3 text-left text-sm transition focus:border-primary",
          !value && "text-muted-foreground",
          className,
        )}
      >
        <span className="flex items-center gap-2 truncate">
          <MapPin className="h-4 w-4 text-muted-foreground" />
          {value || placeholder}
        </span>
        <ChevronsUpDown className="h-4 w-4 shrink-0 text-muted-foreground" />
      </button>
    );

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>{trigger}</PopoverTrigger>
      <PopoverContent align="start" className="w-72 p-0">
        <Command>
          <div className="flex items-center gap-2 border-b border-border/60 px-3">
            <Search className="h-3.5 w-3.5 text-muted-foreground" />
            <CommandInput placeholder="Search Indian city…" className="h-10 border-0 focus:ring-0" />
          </div>
          <CommandList className="max-h-64">
            <CommandEmpty>No matching city.</CommandEmpty>
            <CommandGroup>
              {INDIA_CITIES.map((c) => (
                <CommandItem
                  key={c}
                  value={c}
                  onSelect={() => {
                    onChange(c);
                    setOpen(false);
                  }}
                  className="flex items-center justify-between"
                >
                  <span>{c}</span>
                  {value === c && <Check className="h-4 w-4 text-primary" />}
                </CommandItem>
              ))}
            </CommandGroup>
          </CommandList>
        </Command>
      </PopoverContent>
    </Popover>
  );
}