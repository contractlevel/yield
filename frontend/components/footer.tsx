import { Github, ExternalLink } from "lucide-react"
import Link from "next/link"

export function Footer() {
  return (
    <footer className="bg-slate-50 border-t border-slate-200">
      <div className="mx-auto max-w-7xl px-6 py-12 lg:px-8">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8 justify-items-center md:justify-items-start">
          {/* Brand */}
          <div className="md:col-span-1 text-center md:text-left">
            <Link href="/" className="group">
              <h3 className="text-xl font-bold text-slate-900 group-hover:text-emerald-600 transition-colors">
                YieldCoin
              </h3>
            </Link>
            <p className="mt-2 text-sm text-slate-600">
              Maximize your stablecoin yield across chains with automated optimization.
            </p>
          </div>

          {/* Product */}
          <div className="text-center md:text-left">
            <h4 className="text-sm font-semibold text-slate-900 uppercase tracking-wide mb-4">Product</h4>
            <ul className="space-y-3">
              <li>
                <Link href="/app" className="text-sm text-slate-600 hover:text-slate-900 transition-colors">
                  Launch App
                </Link>
              </li>
              <li>
                <Link href="/bridge" className="text-sm text-slate-600 hover:text-slate-900 transition-colors">
                  Bridge
                </Link>
              </li>
              <li>
                <a href="#features" className="text-sm text-slate-600 hover:text-slate-900 transition-colors">
                  Features
                </a>
              </li>
              <li>
                <a href="#how-it-works" className="text-sm text-slate-600 hover:text-slate-900 transition-colors">
                  How It Works
                </a>
              </li>
            </ul>
          </div>

          {/* Resources */}
          <div className="text-center md:text-left">
            <h4 className="text-sm font-semibold text-slate-900 uppercase tracking-wide mb-4">Resources</h4>
            <ul className="space-y-3">
              <li>
                <a
                  href="https://github.com/contractlevel/yield"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-sm text-slate-600 hover:text-slate-900 transition-colors inline-flex items-center gap-1"
                >
                  Documentation <ExternalLink className="h-3 w-3" />
                </a>
              </li>
              <li>
                <a
                  href="https://medium.com/@contractlevel"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-sm text-slate-600 hover:text-slate-900 transition-colors inline-flex items-center gap-1"
                >
                  Blog <ExternalLink className="h-3 w-3" />
                </a>
              </li>
              <li>
                <a
                  href="https://github.com/contractlevel/yield"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-sm text-slate-600 hover:text-slate-900 transition-colors inline-flex items-center gap-1"
                >
                  GitHub <ExternalLink className="h-3 w-3" />
                </a>
              </li>
              <li>
                <a
                  href="https://ccip.chain.link"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-sm text-slate-600 hover:text-slate-900 transition-colors inline-flex items-center gap-1"
                >
                  CCIP Explorer <ExternalLink className="h-3 w-3" />
                </a>
              </li>
            </ul>
          </div>

          {/* Community */}
          <div className="text-center md:text-left">
            <h4 className="text-sm font-semibold text-slate-900 uppercase tracking-wide mb-4">Community</h4>
            <ul className="space-y-3">
              <li>
                <a
                  href="https://x.com/contractlevel"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-sm text-slate-600 hover:text-slate-900 transition-colors inline-flex items-center gap-1"
                >
                  Contract Level <ExternalLink className="h-3 w-3" />
                </a>
              </li>
              <li>
                <a
                  href="https://chain.link"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-sm text-slate-600 hover:text-slate-900 transition-colors inline-flex items-center gap-1"
                >
                  Chainlink <ExternalLink className="h-3 w-3" />
                </a>
              </li>
            </ul>
          </div>
        </div>

        {/* Bottom section */}
        <div className="mt-12 pt-8 border-t border-slate-200">
          <div className="flex flex-col md:flex-row items-center justify-between">
            <p className="text-sm text-slate-500 text-center md:text-left">
              © 2025 YieldCoin. Built with Chainlink CCIP for cross-chain yield optimization.
            </p>
            <div className="flex items-center space-x-4 mt-4 md:mt-0">
              <a
                href="https://github.com/contractlevel/yield"
                target="_blank"
                rel="noopener noreferrer"
                className="text-slate-400 hover:text-slate-600 transition-colors"
              >
                <Github className="h-5 w-5" />
                <span className="sr-only">GitHub</span>
              </a>
            </div>
          </div>
        </div>
      </div>
    </footer>
  )
}
