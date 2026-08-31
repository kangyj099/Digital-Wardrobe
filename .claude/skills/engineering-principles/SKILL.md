---
name: engineering-principles
description: Prevents magic-value hardcoding in implementation code. Invoke before or while writing or reviewing any implementation code (frontend or backend/data) to verify every literal value has a traceable Source of Truth.
---

# Engineering Principles

## 이 스킬을 언제 쓰나

구현 코드(프론트엔드/백엔드/데이터 불문)를 작성하거나 리뷰하기 **전/도중**에 호출한다. 코드에 리터럴 값을 넣기 직전이 가장 흔한 호출 시점이다.

## 핵심 원칙

코드에서 사용되는 모든 값은 반드시 다음 중 하나를 Source of Truth로 가져야 한다.

(a) 런타임에 외부에서 공급되는 동적 데이터 (사용자 입력, API 응답, DB 조회 결과, 시스템 정보 등)
(b) JSON/XML/CSV 등 데이터 파일 또는 리소스
(c) 코드에 별도로 정의된 사전 합의된 const, enum, design token 등

코드 내에 근거 없는 리터럴 값(magic value)을 직접 사용하는 것은 허용하지 않는다.

예외는 다음 세 가지뿐이다: 삭제될 일회성 테스트 코드 / 명시적으로 표시된 임시 placeholder(데이터 파이프라인 미구축 시) / 긴급 디버그 로깅.

이 원칙은 다른 모든 프로젝트 원칙에 우선하며, 기존 코드를 포함한 전체 코드베이스에 적용한다.

## 닫힌 어휘(closed vocabulary)는 enum이지, 주석 달린 String이 아니다

(c)의 자연스러운 부연: 값의 집합이 미리 정해져 있고 유한하다면(예: 옷 카테고리, 상태값, 정렬 기준) 그 값은 `enum`(또는 동등한 타입 안전 구조)으로 정의해야 한다. `String` 타입에 "허용값: A/B/C" 같은 주석만 달아 두는 것은 이 원칙을 만족하지 않는다 — 컴파일러/타입 시스템이 검증하지 못하는 규칙은 Source of Truth가 아니라 희망 사항이다.

- 나쁜 예: `String status; // "active" | "archived" | "trashed" 중 하나`
- 좋은 예: `enum ItemStatus { active, archived, trashed }`

닫힌 어휘인지 판단이 애매하면(예: 사용자가 자유 입력하는 태그) 이는 (a)나 (b)에 해당할 가능성이 높다 — enum으로 강제하지 말 것.

## 소유권 맵 준수

`docs/reference/architecture/00_OwnershipMap.md`에 등재된 동작·컴포넌트를 그 소유 파일을 경유하지 않고 로컬로 재구현했으면 P1. 문서화된 의도적 예외(맵 비고에 근거 문서가 적힌 경우)는 제외한다.

소유 파일이 **미정**인 행은 P1 대상이 아니다 — 경유할 파일이 아직 없어 준수 가능한 경로가 존재하지 않는다. 대신 그 행에 구현을 하나 더 추가한다는 사실을 PM에게 보고하고, PM이 통합 Task를 앞당길지 복제를 의식적으로 수용할지 판단한다.

## 이 코드베이스에서 이미 확인된 위반 (참고용, 지금 조치하지 말 것)

`docs/work/BACKLOG.md` 기준, 다음 필드가 폐쇄형 어휘인데 bare `String`으로 타입돼 있어 이 원칙 위반으로 이미 식별됨: `ClothingItem.category`, `ClothingItem.season`, `Composition.season`, `ClothingItem.material` (모두 enum 전환 필요). 이 전환 자체는 별도 후속 태스크(Step 3)로 추적 중이며, 이 스킬 호출만으로 지금 손댈 대상은 아니다.
