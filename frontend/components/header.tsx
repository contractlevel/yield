import { Button } from "@/components/ui/button"
import { Github, ExternalLink } from "lucide-react"
import Link from "next/link"

export function Header() {
  return (
    <header className="relative bg-white/95 backdrop-blur-sm border-b border-slate-200/50 sticky top-0 z-50">
      <div className="mx-auto max-w-7xl px-6 lg:px-8">
        <div className="grid grid-cols-3 items-center h-16">
          {/* Logo/Title - Left */}
          <div className="flex items-center justify-start">
            <Link href="/" className="group">
              <h1 className="text-2xl font-bold text-slate-900 group-hover:text-emerald-600 transition-colors">
                YieldCoin
              </h1>
            </Link>
          </div>

          {/* Navigation - Center */}
          <nav className="hidden md:flex items-center justify-center">
            <div className="flex items-center space-x-8">
              <a href="#features" className="text-slate-600 hover:text-slate-900 transition-colors">
                Features
              </a>
              <a href="#how-it-works" className="text-slate-600 hover:text-slate-900 transition-colors">
                How It Works
              </a>
              <a
                href="https://github.com/contractlevel/yield"
                target="_blank"
                rel="noopener noreferrer"
                className="text-slate-600 hover:text-slate-900 transition-colors inline-flex items-center gap-1"
              >
                Docs <ExternalLink className="h-3 w-3" />
              </a>
            </div>
          </nav>

          {/* CTA Buttons - Right */}
          <div className="flex items-center justify-end gap-4">
            <a
              href="https://github.com/contractlevel/yield"
              target="_blank"
              rel="noopener noreferrer"
              className="hidden sm:block"
            >
              <Button variant="ghost" size="sm" className="text-slate-600 hover:text-slate-900">
                <Github className="h-4 w-4 mr-2" />
                GitHub
              </Button>
            </a>
            <Link href="/app">
              <Button className="bg-emerald-600 hover:bg-emerald-700 text-white">Launch App</Button>
            </Link>
          </div>
        </div>
      </div>
    </header>
  )
}
