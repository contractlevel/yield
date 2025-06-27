import { Button } from "@/components/ui/button"
import { ArrowRight } from "lucide-react"
import Link from "next/link"

export function Hero() {
  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden bg-white">
      {/* Background Image with Overlay */}
      <div className="absolute inset-0">
        {/* Background Image using direct blob URL */}
        <div
          className="absolute inset-0 opacity-25"
          style={{
            backgroundImage: `url('https://hebbkx1anhila5yf.public.blob.vercel-storage.com/grokimg.jpg-LAyeuKrIoqLLn3VgaDbtYnjGXqR7Gz.jpeg')`,
            backgroundSize: "cover",
            backgroundPosition: "center",
            backgroundRepeat: "no-repeat",
          }}
        />

        {/* Gradient Overlays for Text Legibility */}
        <div className="absolute inset-0 bg-gradient-to-r from-white/85 via-white/60 to-white/85" />
        <div className="absolute inset-0 bg-gradient-to-b from-white/75 via-transparent to-white/85" />

        {/* Additional center fade for text area */}
        <div
          className="absolute inset-0"
          style={{
            background: "radial-gradient(ellipse 800px 600px at center, rgba(255,255,255,0.7) 0%, transparent 60%)",
          }}
        />
      </div>

      {/* Restored Subtle background grid pattern */}
      <div className="absolute inset-0 opacity-50 bg-[linear-gradient(to_right,#f1f5f9_1px,transparent_1px),linear-gradient(to_bottom,#f1f5f9_1px,transparent_1px)] bg-[size:4rem_4rem] [mask-image:radial-gradient(ellipse_60%_50%_at_50%_0%,#000_70%,transparent_110%)]" />

      {/* Blockchain/Crypto Background Pattern (reduced opacity) */}
      <div className="absolute inset-0 opacity-[0.015]">
        {/* Hexagonal grid pattern */}
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_50%,rgba(16,185,129,0.1)_1px,transparent_1px)] bg-[size:60px_60px]" />

        {/* Digital circuit pattern */}
        <div className="absolute inset-0">
          <svg className="w-full h-full" viewBox="0 0 1200 800" fill="none" xmlns="http://www.w3.org/2000/svg">
            {/* Circuit lines */}
            <path
              d="M0 200 L300 200 L300 400 L600 400 L600 200 L900 200 L900 600 L1200 600"
              stroke="rgba(16,185,129,0.2)"
              strokeWidth="2"
              fill="none"
            />
            <path
              d="M0 600 L200 600 L200 300 L500 300 L500 500 L800 500 L800 100 L1200 100"
              stroke="rgba(16,185,129,0.15)"
              strokeWidth="1.5"
              fill="none"
            />
            <path
              d="M100 0 L100 250 L400 250 L400 450 L700 450 L700 150 L1000 150 L1000 800"
              stroke="rgba(16,185,129,0.1)"
              strokeWidth="1"
              fill="none"
            />

            {/* Circuit nodes */}
            <circle cx="300" cy="200" r="4" fill="rgba(16,185,129,0.3)" />
            <circle cx="600" cy="400" r="4" fill="rgba(16,185,129,0.3)" />
            <circle cx="900" cy="200" r="4" fill="rgba(16,185,129,0.3)" />
            <circle cx="200" cy="600" r="3" fill="rgba(16,185,129,0.25)" />
            <circle cx="500" cy="300" r="3" fill="rgba(16,185,129,0.25)" />
            <circle cx="800" cy="500" r="3" fill="rgba(16,185,129,0.25)" />
            <circle cx="100" cy="250" r="2" fill="rgba(16,185,129,0.2)" />
            <circle cx="400" cy="450" r="2" fill="rgba(16,185,129,0.2)" />
            <circle cx="700" cy="150" r="2" fill="rgba(16,185,129,0.2)" />
          </svg>
        </div>

        {/* Blockchain blocks pattern */}
        <div className="absolute top-20 left-20 w-16 h-16 border border-emerald-500/20 rotate-12" />
        <div className="absolute top-40 left-40 w-12 h-12 border border-emerald-500/15 rotate-45" />
        <div className="absolute top-60 left-10 w-20 h-20 border border-emerald-500/10 -rotate-12" />

        <div className="absolute top-32 right-32 w-14 h-14 border border-emerald-500/20 rotate-45" />
        <div className="absolute top-52 right-52 w-18 h-18 border border-emerald-500/15 -rotate-12" />
        <div className="absolute top-72 right-20 w-16 h-16 border border-emerald-500/10 rotate-12" />

        <div className="absolute bottom-32 left-32 w-12 h-12 border border-emerald-500/15 rotate-45" />
        <div className="absolute bottom-52 left-52 w-16 h-16 border border-emerald-500/10 -rotate-45" />

        <div className="absolute bottom-40 right-40 w-14 h-14 border border-emerald-500/20 rotate-12" />
        <div className="absolute bottom-60 right-10 w-18 h-18 border border-emerald-500/15 -rotate-12" />

        {/* Connecting lines between blocks */}
        <div className="absolute top-28 left-36 w-8 h-0.5 bg-emerald-500/10 rotate-45" />
        <div className="absolute top-48 left-22 w-12 h-0.5 bg-emerald-500/10 -rotate-12" />
        <div className="absolute top-40 right-48 w-10 h-0.5 bg-emerald-500/10 rotate-45" />
        <div className="absolute bottom-48 left-48 w-14 h-0.5 bg-emerald-500/10 rotate-12" />
        <div className="absolute bottom-48 right-28 w-12 h-0.5 bg-emerald-500/10 -rotate-45" />
      </div>

      {/* Floating geometric elements (reduced opacity) */}
      <div className="absolute top-20 right-20 w-32 h-32 bg-emerald-100/15 rounded-full blur-xl animate-pulse" />
      <div
        className="absolute bottom-32 left-20 w-48 h-48 bg-green-100/10 rounded-full blur-2xl animate-pulse"
        style={{ animationDelay: "1s" }}
      />
      <div
        className="absolute top-1/2 right-1/4 w-24 h-24 bg-emerald-200/10 rounded-full blur-xl animate-pulse"
        style={{ animationDelay: "2s" }}
      />

      <div className="relative mx-auto max-w-7xl px-6 py-24 sm:py-32 lg:px-8 z-10">
        <div className="mx-auto max-w-3xl text-center">
          {/* Badge */}
          <div className="mb-8 flex justify-center">
            <div className="inline-flex items-center rounded-full border border-emerald-200 bg-emerald-50/90 backdrop-blur-sm px-4 py-2 text-sm font-medium text-emerald-700 shadow-sm">
              <span>Cross-chain yield optimization</span>
              <ArrowRight className="ml-2 h-4 w-4" />
            </div>
          </div>

          {/* Main heading */}
          <h1 className="text-5xl font-bold tracking-tight text-slate-900 sm:text-6xl lg:text-7xl drop-shadow-sm">
            Earn the{" "}
            <span className="bg-gradient-to-r from-emerald-600 via-green-600 to-emerald-700 bg-clip-text text-transparent">
              highest yield
            </span>{" "}
            on your stablecoins
          </h1>

          {/* Subtitle */}
          <p className="mt-8 text-xl leading-8 text-slate-700 max-w-2xl mx-auto drop-shadow-sm">
            One deposit, maximum yield. YieldCoin automatically finds and captures the highest yields across chains so
            you don't have to monitor, bridge, or manually manage your positions.
          </p>

          {/* CTA buttons */}
          <div className="mt-12 flex items-center justify-center gap-6">
            <Link href="/app">
              <Button
                size="lg"
                className="bg-emerald-600 hover:bg-emerald-700 text-white px-8 py-3 text-base font-semibold shadow-lg hover:shadow-xl transition-all duration-200"
              >
                Start Earning
              </Button>
            </Link>
            <a href="https://github.com/contractlevel/yield" target="_blank" rel="noopener noreferrer">
              <Button
                variant="outline"
                size="lg"
                className="border-slate-300 text-slate-700 hover:bg-slate-50/80 px-8 py-3 text-base font-semibold backdrop-blur-sm shadow-sm"
              >
                View Documentation
              </Button>
            </a>
          </div>
        </div>
      </div>
    </section>
  )
}
