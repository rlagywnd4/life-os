import { AlertTriangle, Dumbbell } from "lucide-react";
import { HealthTabs } from "@/components/health-tabs";
import { workoutMinimumA, workoutMinimumB, workoutRoutineA, workoutRoutineB } from "@/lib/domain/health";

const alternatives = [
  "스텝업이 부담되면 제자리 무릎 들기나 낮은 턱 오르내리기로 바꿉니다.",
  "밴드나 수건 로우가 어렵다면 문틀을 사용하지 말고, 가슴을 펴고 팔꿈치를 뒤로 당기는 동작으로 대체합니다.",
  "플랭크가 불편하면 벽을 짚은 기울어진 플랭크로 바꿉니다."
];

export default function HealthWorkoutPage() {
  return (
    <div className="grid gap-6">
      <header>
        <h1 className="text-3xl font-bold">운동</h1>
        <p className="muted mt-2">전체 운동이 부담되면 최소 버전도 정상적인 완료로 기록합니다.</p>
      </header>
      <HealthTabs />

      <section className="grid gap-3 lg:grid-cols-2">
        <article className="panel">
          <div className="mb-3 flex items-center gap-2">
            <Dumbbell className="text-moss" />
            <h2 className="text-lg font-semibold">주말 운동 A 루틴</h2>
          </div>
          <ol className="grid gap-2">
            {workoutRoutineA.map((item, index) => <li key={item} className="rounded-md border border-line p-3">{index + 1}. {item}</li>)}
          </ol>
          <h3 className="mt-5 font-semibold">A 최소 버전</h3>
          <ul className="mt-2 grid gap-2">
            {workoutMinimumA.map((item) => <li key={item} className="rounded-md bg-paper p-3 text-sm">{item}</li>)}
          </ul>
        </article>

        <article className="panel">
          <div className="mb-3 flex items-center gap-2">
            <Dumbbell className="text-sky" />
            <h2 className="text-lg font-semibold">주말 운동 B 루틴</h2>
          </div>
          <ol className="grid gap-2">
            {workoutRoutineB.map((item, index) => <li key={item} className="rounded-md border border-line p-3">{index + 1}. {item}</li>)}
          </ol>
          <h3 className="mt-5 font-semibold">B 최소 버전</h3>
          <ul className="mt-2 grid gap-2">
            {workoutMinimumB.map((item) => <li key={item} className="rounded-md bg-paper p-3 text-sm">{item}</li>)}
          </ul>
        </article>
      </section>

      <section className="panel grid gap-3">
        <h2 className="text-lg font-semibold">대체 동작</h2>
        {alternatives.map((item) => <p key={item} className="rounded-md border border-line p-3 text-sm">{item}</p>)}
      </section>

      <section className="panel flex gap-3">
        <AlertTriangle className="mt-1 shrink-0 text-amber" />
        <p className="text-sm leading-6 text-ink/75">
          통증이 생기면 운동을 중단하고 무리하지 마세요. 이 안내는 일반적인 안전 안내이며 의료 진단이 아닙니다.
        </p>
      </section>
    </div>
  );
}
