"use client";

import { Plus, Trash2 } from "lucide-react";
import { useState } from "react";
import { ActionButton } from "@/components/action-button";
import { createProjectPlan } from "@/features/projects/actions";

type ProjectSetupFormProps = {
  sourceInbox?: { id: string; title: string; description: string | null };
};

const stepTitles = ["기본 정보", "목표와 완료 기준", "기간", "단계", "첫 다음 행동"];

export function ProjectSetupForm({ sourceInbox }: ProjectSetupFormProps) {
  const [step, setStep] = useState(0);
  const [stages, setStages] = useState<string[]>([]);
  const [stageInput, setStageInput] = useState("");

  function addStage() {
    const title = stageInput.trim();
    if (!title) return;
    setStages((current) => [...current, title]);
    setStageInput("");
  }

  return (
    <form action={createProjectPlan} className="panel grid gap-5">
      {sourceInbox ? <input type="hidden" name="sourceInboxId" value={sourceInbox.id} /> : null}
      <ol className="grid grid-cols-5 gap-1" aria-label="프로젝트 설정 단계">
        {stepTitles.map((title, index) => (
          <li key={title} className={`rounded px-2 py-2 text-center text-xs font-semibold ${index === step ? "bg-ink text-white" : index < step ? "bg-moss/15 text-moss" : "bg-paper text-ink/60"}`} aria-current={index === step ? "step" : undefined}>
            <span className="hidden sm:inline">{index + 1}. </span>{title}
          </li>
        ))}
      </ol>

      <div hidden={step !== 0} className="grid gap-3">
        <div>
          <h2 className="text-xl font-bold">무엇을 만들고 싶나요?</h2>
          <p className="muted mt-1">프로젝트의 제목과 배경을 먼저 적습니다.</p>
        </div>
        <label className="grid gap-1"><span className="label">프로젝트 제목</span><input className="field" name="title" required maxLength={160} defaultValue={sourceInbox?.title ?? ""} /></label>
        <label className="grid gap-1"><span className="label">설명</span><textarea className="field min-h-28" name="description" maxLength={2000} defaultValue={sourceInbox?.description ?? ""} placeholder="어떤 프로젝트인지 간단히 적어보세요." /></label>
      </div>

      <div hidden={step !== 1} className="grid gap-3">
        <div><h2 className="text-xl font-bold">결과를 선명하게 만듭니다</h2><p className="muted mt-1">목표와 완료 기준은 서로 다르게 적습니다.</p></div>
        <label className="grid gap-1"><span className="label">만들고 싶은 결과</span><textarea className="field min-h-28" name="goal" maxLength={2000} placeholder="예: AI와 머신러닝의 기본 원리를 이해하고 직접 실습한다." /></label>
        <label className="grid gap-1"><span className="label">완료 기준</span><textarea className="field min-h-28" name="completionCriteria" maxLength={2000} placeholder="예: 머신러닝 기초 미니 프로젝트 하나를 완성한다." /></label>
      </div>

      <div hidden={step !== 2} className="grid gap-3">
        <div><h2 className="text-xl font-bold">기간을 정합니다</h2><p className="muted mt-1">목표일은 나중에 정해도 됩니다.</p></div>
        <div className="grid gap-3 sm:grid-cols-2">
          <label className="grid gap-1"><span className="label">시작일</span><input className="field" name="startedDate" type="date" /></label>
          <label className="grid gap-1"><span className="label">목표 완료일</span><input className="field" name="targetDate" type="date" /></label>
        </div>
      </div>

      <div hidden={step !== 3} className="grid gap-3">
        <div><h2 className="text-xl font-bold">큰 단계를 나눕니다</h2><p className="muted mt-1">건너뛰어도 됩니다. 상세 화면에서 언제든 추가할 수 있습니다.</p></div>
        <div className="flex gap-2"><input className="field" value={stageInput} onChange={(event) => setStageInput(event.target.value)} onKeyDown={(event) => { if (event.key === "Enter") { event.preventDefault(); addStage(); } }} placeholder="예: 학습 환경 준비" maxLength={160} /><button className="btn-secondary shrink-0" type="button" onClick={addStage}><Plus size={18} /> 추가</button></div>
        <ol className="grid gap-2">
          {stages.map((stage, index) => <li key={`${stage}-${index}`} className="flex items-center justify-between rounded-md border border-line bg-paper px-3 py-2"><span>{index + 1}. {stage}</span><button type="button" className="rounded p-1 text-ink/60 hover:bg-white" onClick={() => setStages((current) => current.filter((_, itemIndex) => itemIndex !== index))} aria-label={`${stage} 단계 삭제`}><Trash2 size={16} /></button><input type="hidden" name="stages" value={stage} /></li>)}
        </ol>
      </div>

      <div hidden={step !== 4} className="grid gap-3">
        <div><h2 className="text-xl font-bold">가장 먼저 할 행동은?</h2><p className="muted mt-1">완벽한 계획보다 바로 시작할 수 있는 작은 행동이 중요합니다.</p></div>
        <label className="grid gap-1"><span className="label">첫 다음 행동</span><input className="field" name="firstActionTitle" maxLength={160} placeholder="예: ai-study 폴더 만들기" /></label>
      </div>

      <div className="flex flex-wrap justify-between gap-2 border-t border-line pt-4">
        <div className="flex gap-2">
          {step > 0 ? <button type="button" className="btn-secondary" onClick={() => setStep((current) => current - 1)}>이전</button> : null}
          {step < stepTitles.length - 1 ? <button type="button" className="btn-primary" onClick={() => setStep((current) => current + 1)}>다음</button> : null}
        </div>
        <div className="flex gap-2">
          <ActionButton className="btn-secondary" name="status" value="DRAFT" pendingLabel="저장 중">초안 저장</ActionButton>
          {step === stepTitles.length - 1 ? <ActionButton className="btn-primary" name="status" value="ACTIVE" pendingLabel="만드는 중">프로젝트 시작</ActionButton> : null}
        </div>
      </div>
    </form>
  );
}
