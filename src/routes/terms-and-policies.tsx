import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { useState } from "react";
import { ArrowLeft, ShieldCheck, ScrollText } from "lucide-react";

export const Route = createFileRoute("/terms-and-policies")({
  head: () => ({
    meta: [
      { title: "Terms & Privacy · tribeX" },
      { name: "description", content: "tribeX terms of use and privacy policy — safety, host guidelines, data usage, and liability." },
    ],
  }),
  component: TermsPage,
});

function TermsPage() {
  const navigate = useNavigate();
  const [tab, setTab] = useState<"terms" | "privacy">("terms");

  return (
    <div className="page-in flex flex-col gap-5 px-5 pt-6 pb-10">
      <header className="flex items-center gap-3">
        <button
          onClick={() => navigate({ to: "/profile" })}
          className="flex h-9 w-9 items-center justify-center rounded-full border border-border/60 bg-card transition hover:border-primary/60 active:scale-95"
          aria-label="Back"
        >
          <ArrowLeft className="h-4 w-4" />
        </button>
        <div>
          <p className="text-xs font-medium uppercase tracking-[0.18em] text-muted-foreground">Legal</p>
          <h1 className="mt-1 text-2xl font-bold tracking-tight">Terms & Privacy</h1>
        </div>
      </header>

      <div className="flex rounded-full border border-border/60 bg-card p-1 text-xs">
        <button
          onClick={() => setTab("terms")}
          className={`flex flex-1 items-center justify-center gap-1.5 rounded-full px-3 py-2 font-semibold transition ${
            tab === "terms" ? "bg-foreground text-background" : "text-muted-foreground"
          }`}
        >
          <ScrollText className="h-3.5 w-3.5" /> Terms
        </button>
        <button
          onClick={() => setTab("privacy")}
          className={`flex flex-1 items-center justify-center gap-1.5 rounded-full px-3 py-2 font-semibold transition ${
            tab === "privacy" ? "bg-foreground text-background" : "text-muted-foreground"
          }`}
        >
          <ShieldCheck className="h-3.5 w-3.5" /> Privacy
        </button>
      </div>

      <article className="prose prose-sm max-w-none rounded-3xl border border-border/60 bg-card p-5 text-sm leading-relaxed text-foreground">
        {tab === "terms" ? <TermsContent /> : <PrivacyContent />}
      </article>

      <p className="text-center text-[11px] text-muted-foreground/70">
        Last updated: {new Date().toLocaleDateString([], { year: "numeric", month: "long", day: "numeric" })}
      </p>
    </div>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="mb-5 last:mb-0">
      <h2 className="mb-1.5 text-sm font-bold uppercase tracking-wider text-primary">{title}</h2>
      <div className="space-y-2 text-muted-foreground">{children}</div>
    </section>
  );
}

function TermsContent() {
  return (
    <>
      <Section title="1. Eligibility">
        <p>You must be at least 18 years old to create an account, host a plan, or join an activity on tribeX. By using tribeX you confirm that you meet this requirement.</p>
      </Section>
      <Section title="2. User Safety & Personal Responsibility">
        <p>tribeX is a discovery platform. All meet-ups, activities, and interactions happen offline between independent users. You participate at your own personal risk and assume full responsibility for your safety, conduct, and belongings.</p>
        <p>Always meet in public places, share your live location with a trusted contact, and trust your instincts. Report unsafe behaviour immediately.</p>
      </Section>
      <Section title="3. Host Guidelines">
        <p>Hosts are responsible for the accuracy of the plan details (title, location, time, cost, slots). Hosts must not organise illegal activities, gambling, adult-only content, or anything that risks the safety of participants.</p>
      </Section>
      <Section title="4. Prohibited Conduct">
        <p>You agree not to harass, threaten, discriminate against, or misrepresent yourself to other users. Sharing personal contact details of other members without consent is prohibited.</p>
      </Section>
      <Section title="5. Liability Disclaimer">
        <p>tribeX does not verify users, vet activities, or supervise meet-ups. To the fullest extent permitted by law, tribeX and its team are not liable for any injury, loss, damage, dispute, or claim arising from your use of the app or participation in any activity.</p>
      </Section>
      <Section title="6. Account Termination">
        <p>We may suspend or delete accounts that violate these Terms, receive credible safety reports, or misuse the platform, with or without notice.</p>
      </Section>
      <Section title="7. Changes">
        <p>We may update these Terms as the product evolves. Continued use after an update means you accept the revised Terms.</p>
      </Section>
      <Section title="8. Contact">
        <p>Questions? Reach us at <a href="mailto:tribex.apk@gmail.com" className="font-semibold text-primary">tribex.apk@gmail.com</a>.</p>
      </Section>
    </>
  );
}

function PrivacyContent() {
  return (
    <>
      <Section title="1. Data We Collect">
        <p>Account details you provide (name, email, phone, gender, city, bio, avatar), plans you host or join, chat messages, and your chosen or GPS-derived location. We collect only what the product needs to work.</p>
      </Section>
      <Section title="2. How We Use Your Data">
        <p>To show you nearby plans, connect you with hosts and squads, secure your account, and improve tribeX. We do not sell your personal data to advertisers.</p>
      </Section>
      <Section title="3. Location Data">
        <p>Location is used only to surface nearby activities. GPS is requested with your explicit permission and can be revoked from your device settings at any time. You can clear the stored location from your profile.</p>
      </Section>
      <Section title="4. Sharing With Others">
        <p>Your public profile (name, avatar, bio, city, rating) is visible to hosts and members of plans you interact with. Chat messages are visible to members of that plan's chat.</p>
      </Section>
      <Section title="5. Service Providers">
        <p>We use trusted providers to run the app (authentication, database, storage, geocoding). They process data only to deliver these services.</p>
      </Section>
      <Section title="6. Data Retention & Deletion">
        <p>Your data is retained while your account is active. Email <a href="mailto:tribex.apk@gmail.com" className="font-semibold text-primary">tribex.apk@gmail.com</a> to delete your account and associated data.</p>
      </Section>
      <Section title="7. Security">
        <p>We use industry-standard encryption in transit and at rest, row-level access rules, and least-privilege server access. No internet service can be 100% secure — please use a strong, unique password.</p>
      </Section>
      <Section title="8. Children">
        <p>tribeX is not intended for anyone under 18. We do not knowingly collect data from minors.</p>
      </Section>
      <Section title="9. Contact">
        <p>Privacy questions? Email <a href="mailto:tribex.apk@gmail.com" className="font-semibold text-primary">tribex.apk@gmail.com</a>.</p>
      </Section>
    </>
  );
}