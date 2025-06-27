import { Shield, Zap, Globe, TrendingUp } from "lucide-react"

const features = [
  {
    name: "Automated Yield Optimization",
    description: "Our smart contracts continuously monitor and capture the highest yields across DeFi protocols.",
    icon: TrendingUp,
  },
  {
    name: "Cross-Chain Compatible",
    description: "Deposit on any supported chain and earn from opportunities across the entire ecosystem.",
    icon: Globe,
  },
  {
    name: "One-Click Simplicity",
    description: "No need to monitor markets, bridge assets, or manage multiple positions. Just deposit and earn.",
    icon: Zap,
  },
  {
    name: "Battle-Tested Security",
    description: "Built with security-first principles using proven protocols like Aave and Compound.",
    icon: Shield,
  },
]

export function Features() {
  return (
    <section className="relative py-24 sm:py-32 bg-slate-50 overflow-hidden">
      {/* Floating elements */}
      <div className="absolute top-10 left-10 w-24 h-24 bg-emerald-100/40 rounded-full blur-xl" />
      <div className="absolute bottom-20 right-20 w-36 h-36 bg-green-100/30 rounded-full blur-2xl" />

      <div className="relative mx-auto max-w-7xl px-6 lg:px-8">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="text-base font-semibold leading-7 text-emerald-600 uppercase tracking-wide">
            Contract Level Yield
          </h2>
          <p className="mt-4 text-3xl font-bold tracking-tight text-slate-900 sm:text-4xl">DeFi yield, simplified</p>
          <p className="mt-6 text-lg leading-8 text-slate-600">
            Stop juggling multiple protocols and chains. YieldCoin handles the complexity so you can focus on what
            matters - earning maximum yield on your stablecoins.
          </p>
        </div>

        <div className="mx-auto mt-16 max-w-2xl sm:mt-20 lg:mt-24 lg:max-w-none">
          <dl className="grid max-w-xl grid-cols-1 gap-x-8 gap-y-16 lg:max-w-none lg:grid-cols-2">
            {features.map((feature) => (
              <div
                key={feature.name}
                className="flex flex-col backdrop-blur-sm bg-white/60 rounded-xl p-6 border border-white/20"
              >
                <dt className="text-base font-semibold leading-7 text-slate-900">
                  <div className="mb-6 flex h-12 w-12 items-center justify-center rounded-lg bg-emerald-600">
                    <feature.icon className="h-6 w-6 text-white" aria-hidden="true" />
                  </div>
                  {feature.name}
                </dt>
                <dd className="mt-1 flex flex-auto flex-col text-base leading-7 text-slate-600">
                  <p className="flex-auto">{feature.description}</p>
                </dd>
              </div>
            ))}
          </dl>
        </div>
      </div>
    </section>
  )
}
