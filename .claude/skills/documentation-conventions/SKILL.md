---
name: documentation-conventions
description: How to write and update this project's Reference documents (docs/reference/**) — living-document discipline and concise-writing rules. Invoke before writing to or editing any file under docs/reference/**.
---

# Documentation Conventions

## 이 스킬을 언제 쓰나

`docs/reference/**` 아래 어떤 파일이든 쓰기/수정하기 전에 호출한다.

## 원문 (Workflow_Project.md §1.4, §1.5 — verbatim)

### 1.4 Living Documents

Reference documents must always have only a single up-to-date version.

Do not create copies such as Version2, Final, or Final_Final.

### 1.5 Concise Writing

Reference documents are written as concisely as possible, without duplication, as long as doing so does not compromise exact meaning.

- This applies to newly authored or edited content. It does not retroactively shorten existing History document entries (`Decision.md` / `TechnicalDebt.md`) — those are append-only per §6.
- History document entries are held to a different standard: per §1.3 (Source of Truth), they must carry enough context to stand in for a lost conversation, so more detail is expected there than in Reference documents.
- When conciseness would conflict with the reachability requirement in §3 "Skill-Internal Ledgers vs. Official Handoff" (transcribing content directly so a fresh session can find it), reachability wins — do not replace necessary inline detail with a link just to shorten a document.

## 훑을 수 있게 쓰기

Reference 문서는 사람이 검토한다. 정보량이 아니라 **훑기 가능성**이 검토 비용을 정한다.

아래 다섯 가지를 지킨다.

**1. 결론을 문단 첫 줄에 둔다.**

근거는 그 뒤에 붙인다. 첫 줄만 읽고 넘어갈 수 있어야 한다.

**2. 한 문장에 한 명제만 담는다.**

주장과 근거를 한 문장에 함께 싣지 않는다. 마침표로 끊는다.

**3. 대시(`—`)로 절을 잇지 않는다.**

대시는 표 셀이나 목록의 구분자로만 쓴다. 산문에서 대시로 절을 붙이면 한 문장이 서너 줄이 된다.

한국어는 술어가 문장 끝에 온다. 절을 쌓으면 판정이 계속 뒤로 밀려 문장 끝까지 읽어야 뜻이 닫힌다.

**4. 볼드는 랜드마크로만 쓴다.**

문단이나 항목의 이름에 쓴다. 문장 안에서도 그 문장의 핵심 구절이면 쓴다.

개수가 적어야 기능한다. 한 화면에 여러 개가 보이면 다시 균일해져 강조가 죽는다.

**5. 밀도를 균일하게 만들지 않는다.**

짧은 줄과 긴 줄을 섞는다. 모든 문장이 똑같이 조밀하면 눈이 착지할 지점이 사라져 정독 외에는 방법이 없어진다.

**6. 헤딩은 명사구로 쓴다.**

"어떻게 적나"가 아니라 "기재 요령"으로 쓴다.

조사와 어미가 붙지 않아 grep과 다른 문서에서의 §참조가 안정적이다. 문장형 헤딩은 본문과 밀도가 같아져 헤딩으로 보이지 않는다.

### 항목화

규칙이나 항목이 셋 이상이면 불렛으로 나열한다. 산문 문단은 어디서 한 규칙이 끝나는지 추론하게 만든다.

한 규칙의 근거나 부연은 하위 줄로 들여쓴다.

형제 불렛으로 올리면 독립 규칙으로 읽혀 적용 조건이 사라진다. "예외가 있으면 A" 아래의 "B를 비고에 밝힌다"가 형제가 되면 B가 항상 적용되는 것처럼 읽힌다.

### 표 안의 서술

서술은 셀 안에 둔다. 각주나 별도 절로 빼지 않는다.

셀 안에서는 한 문장마다 `<br>`로 줄을 나눈다. 위 2번 원칙을 셀 안에서도 지키는 방법이다.

표를 읽다가 다른 절로 튀는 비용이 셀이 길어지는 비용보다 크다. `00_OwnershipMap.md`가 기준 사례다.

### §1.5와의 관계

충돌하지 않는다.

위 규칙은 문장 모양과 배치만 바꾼다. 같은 내용을 여러 번 반복하는 것은 §1.5대로 금지다. 읽기 쉽게 만들려고 중복을 넣지 않는다.
