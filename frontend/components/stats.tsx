"use client"

import { useEffect, useState } from "react"

export function Stats() {
  const [stats, setStats] = useState({
    totalValueLocked: "0",
    currentAPY: "0",
    totalUsers: "0",
  })

  useEffect(() => {
    const timer = setTimeout(() => {
      setStats({
        totalValueLocked: "2,456,789",
        currentAPY: "8.5",
        totalUsers: "1,337",
      })
    }, 1000)

    return () => clearTimeout(timer)
  }, [])

  return (
    <section className="relative bg-slate-900 py-24 sm:py-32 overflow-hidden">
      {/* Abstract background with gradient */}
      <div className="absolute inset-0">
        <div className="absolute inset-0 bg-gradient-to-br from-slate-900/95 via-slate-900/98 to-emerald-900/95" />
      </div>

      {/* Floating elements */}
      <div className="absolute top-20 left-20 w-32 h-32 bg-emerald-500/10 rounded-full blur-2xl" />
      <div className="absolute bottom-20 right-20 w-40 h-40 bg-green-500/10 rounded-full blur-3xl" />

      <div className="relative mx-auto max-w-7xl px-6 lg:px-8">
        <div className="mx-auto max-w-2xl text-center mb-16">
          <h2 className="text-3xl font-bold tracking-tight text-white sm:text-4xl">Live protocol metrics</h2>
          <p className="mt-4 text-lg leading-8 text-slate-300">
            Real-time data from our yield optimization engine across all supported chains.
          </p>
        </div>

        <dl className="mx-auto grid max-w-2xl grid-cols-1 gap-x-8 gap-y-10 text-center sm:grid-cols-2 lg:mx-0 lg:max-w-none lg:grid-cols-3">
          <div className="flex flex-col gap-y-3 backdrop-blur-sm bg-white/5 rounded-xl p-6 border border-white/10">
            <dt className="text-base leading-7 text-slate-300">Total Value Locked</dt>
            <dd className="order-first text-3xl font-bold tracking-tight text-white sm:text-5xl">
              ${stats.totalValueLocked}
            </dd>
          </div>
          <div className="flex flex-col gap-y-3 backdrop-blur-sm bg-white/5 rounded-xl p-6 border border-white/10">
            <dt className="text-base leading-7 text-slate-300">Current APY</dt>
            <dd className="order-first text-3xl font-bold tracking-tight text-white sm:text-5xl">
              {stats.currentAPY}%
            </dd>
          </div>
          <div className="flex flex-col gap-y-3 backdrop-blur-sm bg-white/5 rounded-xl p-6 border border-white/10">
            <dt className="text-base leading-7 text-slate-300">Active Users</dt>
            <dd className="order-first text-3xl font-bold tracking-tight text-white sm:text-5xl">{stats.totalUsers}</dd>
          </div>
        </dl>
      </div>
    </section>
  )
}
