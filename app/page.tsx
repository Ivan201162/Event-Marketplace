import HomeHeader from '@/components/home-header'
import BestSpecialists from '@/components/best-specialists'
import Feed from '@/components/feed'
import MobileNav from '@/components/mobile-nav'

export default function HomePage() {
  return (
    <div className="min-h-screen bg-neutral-900 pb-16 md:pb-0">
      <HomeHeader />
      <BestSpecialists />
      <Feed />
      <MobileNav />
    </div>
  )
}