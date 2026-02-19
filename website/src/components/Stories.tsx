import { useCallback, useEffect, useRef, useState } from "react";

interface StoryItem {
  title: string;
  subtitle: string;
  thumbnail: string;
}

interface StoriesProps {
  items: StoryItem[];
  duration?: number;
}

export default function Stories({ items, duration = 5000 }: StoriesProps) {
  const [active, setActive] = useState(0);
  const [fillWidth, setFillWidth] = useState(0);
  const timerRef = useRef<ReturnType<typeof setTimeout>>();

  const goTo = useCallback(
    (index: number) => {
      const wrapped = ((index % items.length) + items.length) % items.length;
      setFillWidth(0);
      setActive(wrapped);
    },
    [items.length],
  );

  const goForward = useCallback(() => goTo(active + 1), [active, goTo]);
  const goBack = useCallback(() => goTo(active - 1), [active, goTo]);

  // Animate fill after active changes
  useEffect(() => {
    // Double rAF to ensure the browser has painted 0% width first
    let id1: number;
    let id2: number;
    id1 = requestAnimationFrame(() => {
      id2 = requestAnimationFrame(() => {
        setFillWidth(100);
      });
    });
    return () => {
      cancelAnimationFrame(id1);
      cancelAnimationFrame(id2);
    };
  }, [active]);

  // Auto-advance timer
  useEffect(() => {
    timerRef.current = setTimeout(goForward, duration);
    return () => clearTimeout(timerRef.current);
  }, [active, duration, goForward]);

  function handleClick(e: React.MouseEvent<HTMLDivElement>) {
    const rect = e.currentTarget.getBoundingClientRect();
    const x = e.clientX - rect.left;
    if (x < rect.width / 2) {
      goBack();
    } else {
      goForward();
    }
  }

  const item = items[active];

  return (
    <div
      className="rounded-xl overflow-hidden bg-green-900 cursor-pointer select-none relative"
      onClick={handleClick}
    >


      {/* Thumbnail */}
      <div className="aspect-video bg-green-950">
        <img
          src={item.thumbnail}
          alt={item.title}
          className="w-full h-full object-cover"
        />
      </div>

      {/* Text */}
      <div className="px-2 py-2">
        <div className="font-bold leading-tight">{item.title}</div>
        <div className="text-xs" style={{ opacity: 0.6 }}>
          {item.subtitle}
        </div>
      </div>

      {/* Progress bars */}
      <div className="absolute top-0 left-0 right-0 z-10 flex gap-1 p-2">
        {items.map((_, i) => (
          <div
            key={i}
            className="h-0.5 flex-1 rounded-full overflow-hidden"
            style={{ backgroundColor: "rgba(255,255,255,0.3)" }}
          >
            <div
              className="h-full rounded-full"
              style={{
                backgroundColor: "white",
                width:
                  i < active ? "100%" : i === active ? `${fillWidth}%` : "0%",
                transition:
                  i === active && fillWidth === 100
                    ? `width ${duration}ms linear`
                    : "none",
              }}
            />
          </div>
        ))}
      </div>
    </div>
  );
}
