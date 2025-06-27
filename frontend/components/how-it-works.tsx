import { ArrowRight } from "lucide-react"

const steps = [
  {
    id: "01",
    name: "Connect & Deposit",
    description: "Connect your wallet and deposit USDC on any supported blockchain network.",
  },
  {
    id: "02",
    name: "Receive YieldCoin",
    description: "Instantly receive YieldCoin tokens representing your proportional share of the system.",
  },
  {
    id: "03",
    name: "Automated Optimization",
    description: "Our infrastructure continuously finds and captures the highest yields across protocols.",
  },
  {
    id: "04",
    name: "Compound Returns",
    description: "Watch your yield compound automatically while maintaining full liquidity and control.",
  },
]

export function HowItWorks() {
  return (
    <section className="relative py-24 sm:py-32 bg-white overflow-hidden">
      {/* Geometric elements */}

      <div className="relative mx-auto max-w-7xl px-6 lg:px-8">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="text-base font-semibold leading-7 text-emerald-600 uppercase tracking-wide">How it works</h2>
          <p className="mt-4 text-3xl font-bold tracking-tight text-slate-900 sm:text-4xl">
            Four simple steps to maximum yield
          </p>
          <p className="mt-6 text-lg leading-8 text-slate-600">Yield optimization made simple and accessible.</p>
        </div>

        <div className="mx-auto mt-16 max-w-2xl sm:mt-20 lg:mt-24 lg:max-w-none">
          <div className="grid max-w-xl grid-cols-1 gap-x-8 gap-y-10 lg:max-w-none lg:grid-cols-4">
            {steps.map((step, stepIdx) => (
              <div key={step.name} className="relative flex flex-col items-center text-center">
                {/* Step card */}
                <div className="backdrop-blur-sm bg-white/70 rounded-xl p-6 border border-white/30 w-full">
                  {/* Step number */}
                  <div className="flex h-16 w-16 items-center justify-center rounded-full bg-emerald-600 text-white font-bold text-lg mb-6 mx-auto">
                    {step.id}
                  </div>

                  <h3 className="text-lg font-semibold leading-7 text-slate-900 mb-2">{step.name}</h3>
                  <p className="text-base leading-7 text-slate-600">{step.description}</p>
                </div>

                {/* Arrow connector */}
                {stepIdx < steps.length - 1 && (
                  <div className="hidden lg:block absolute top-1/2 left-full w-8 -translate-y-1/2">
                    <ArrowRight className="h-5 w-5 text-slate-400 mx-auto" />
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  )
}
