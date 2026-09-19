# SCBK VOC (scbk_voc) 수정분 산출물 형식

SCBK 는 소스가 이미 **내부망에 반입된 상태**라, 이후 변경은 내부에서 사람이 직접 손으로 반영한다. 그래서 zip 하나가 아니라 "사람이 보고 따라 할 수 있는" 폴더를 만든다. 기준 문서: `/volume2/claude/scbk_voc/수정/README.md` (작업 전 반드시 읽을 것 — 색인 표가 거기 있다).

- 소스: `/volume2/claude/repo/SCBK_VOC` (JDK21 / Jakarta EE 10, Tomcat10·WildFly 로컬 기동은 프로젝트 자료 참고), 배치는 `SCBK-VOC-BATCH`.
- 참고자료: `/volume2/claude/scbk_voc/` — `수정/`, `Error/`(오류별 수정방법·인수인계·동일패턴 점검 md), `SIT/`, `DB/`, `반입/`.
- 기존 예시: `수정/2026-09-06/D-12_VOC0002_리더전달_function중복/`.

## 폴더 구조

```
수정/
└─ <YYYY-MM-DD>/
   └─ <결함번호_대상_요약>/          예: D-12_VOC0002_리더전달_function중복
      ├─ README.md        배경 · 변경 파일 목록 · 수동 적용 절차 · 검증 · 원복
      ├─ patch.diff       git diff (외부 개발 PC 저장소 기준)
      ├─ 01_파일/         변경 후 파일 전체 — 리포 상대경로 유지 (내부에서 통째로 덮어쓰기)
      └─ 02_DB/           apply.sql · rollback.sql · verify.sql (+ run_sql.py 개발DB용)
```

`make_fix_package.py --layout scbk --out /volume2/claude/scbk_voc/수정/<YYYY-MM-DD> --name <결함번호_대상_요약> --no-zip` 으로 골격을 만든다.

## README.md 구성

```
# D-NN — <한 줄 제목> (yyyy-MM-dd)

## 1. 배경                      증상, 발견 경위(SIT 시나리오 번호 등), 근본 원인
## 2. 변경 내용 (외부 개발 PC 저장소 기준, `patch.diff`)
                                 파일별 변경 요약 표: 파일 | 변경 | 이유
## 3. 내부망 수동 적용 절차        번호 매긴 단계. 파일 덮어쓰기 vs 부분 수정(줄 위치·전후 문맥) 구분,
                                 DB 는 apply → verify 순서, 재기동 필요 여부
## 4. 개발DB 적용 기록            언제 무엇을 적용했고 verify 결과가 어땠는지 (미적용이면 미적용)
## 5. 남은 확인                   요건 확정 대기, 내부망에서만 확인 가능한 것, 원복 방법
```

내부망 담당자는 diff 도구 없이 편집기로 고치는 경우가 많다 — "어느 파일의 어느 메서드/쿼리 id 를 어떻게"가 README 만으로 따라 할 수 있게 쓴다.

## 색인 표 갱신

`수정/README.md` 맨 아래 표에 한 줄 추가:

`| 일자 | 폴더 | 결함 | 요약 | 개발DB | 내부망 |` — 개발DB/내부망 칸은 `적용(S-NN)` / `미적용`. 내부망 반영 여부는 사용자가 알려 줄 때만 바꾼다.

## 오류 분석 문서 (`Error/`)

ORA-xxxxx 같은 오류성 결함은 전례대로 md 3종을 만든다: `<오류>_수정방법.md`(원인·수정), `<오류>_동일패턴_점검.md`(같은 패턴 전수 검색 결과), `<오류>_인수인계.md`(내부망 담당자용 요약).
