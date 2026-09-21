#!/usr/bin/env python3
"""수정소스 패키지 생성기 — 원본/수정본/patch/DB/증적/README 골격을 만들고 zip 으로 묶는다.

리포는 읽기만 한다(git show / git diff / 파일 복사). 표준 라이브러리만 사용.

  make_fix_package.py --repo <리포> --name 결함34수정 --out <출력폴더>
      [--base HEAD] [--to WORKTREE|<커밋>] [--files 경로...] [--sql 파일...] [--evidence 파일...]
      [--layout wrb|scbk] [--eol match|crlf|lf] [--date YYYYMMDD] [--no-zip] [--rezip] [--force]

  --files 생략 시 base..to 의 변경 파일 전부(WORKTREE 면 추적 중 수정 + 신규 미추적 파일).
  --eol    : 원본/수정본 텍스트 파일의 줄끝. match(기본)=원본을 수정본에 맞춤, crlf=둘 다 CRLF(Windows 반영 환경), lf=둘 다 LF.
             patch 는 리포 기준 그대로 둔다.
  --rezip  : 폴더는 그대로 두고(README 를 채운 뒤) zip 만 다시 묶는다.
"""
import argparse, datetime, os, shutil, subprocess, sys, zipfile


def git(repo, *args, text=True, check=True):
    r = subprocess.run(['git', '-C', repo, '-c', 'core.quotepath=false', *args], capture_output=True)
    if check and r.returncode != 0:
        sys.exit('git %s 실패: %s' % (' '.join(args), r.stderr.decode('utf-8', 'replace').strip()))
    return r.stdout.decode('utf-8', 'replace') if text else r.stdout


def changed_files(repo, base, to):
    if to == 'WORKTREE':
        mod = git(repo, 'diff', '--name-status', base).splitlines()
        new = ['A\t' + p for p in git(repo, 'ls-files', '--others', '--exclude-standard').splitlines()]
        lines = mod + new
    else:
        lines = git(repo, 'diff', '--name-status', base, to).splitlines()
    out = []
    for ln in lines:
        parts = ln.split('\t')
        st, path = parts[0][0], parts[-1]          # rename(R100 old new) 은 새 경로 기준
        out.append((st, path))
    return out


def read_base(repo, base, path):
    r = subprocess.run(['git', '-C', repo, 'show', '%s:%s' % (base, path)], capture_output=True)
    return r.stdout if r.returncode == 0 else None


def read_to(repo, to, path):
    if to == 'WORKTREE':
        p = os.path.join(repo, path)
        return open(p, 'rb').read() if os.path.isfile(p) else None
    return read_base(repo, to, path)


def match_eol(src, like):
    """원본의 줄끝을 수정본과 같게 맞춘다(Windows 반영 환경에서 비교 도구가 전 줄 변경으로 보지 않게)."""
    if src is None or like is None or b'\0' in src[:8000]:
        return src
    if b'\r\n' in like and b'\r\n' not in src:
        return src.replace(b'\n', b'\r\n')
    if b'\r\n' not in like and b'\r\n' in src:
        return src.replace(b'\r\n', b'\n')
    return src


def force_eol(data, eol):
    if data is None or eol == 'match' or b'\0' in data[:8000]:
        return data
    data = data.replace(b'\r\n', b'\n')
    return data.replace(b'\n', b'\r\n') if eol == 'crlf' else data


def flat_names(paths):
    """평면 폴더용 파일명. 같은 이름이 겹치면 상위폴더명__파일명."""
    base = [os.path.basename(p) for p in paths]
    names = {}
    for p, b in zip(paths, base):
        names[p] = b if base.count(b) == 1 else '%s__%s' % (os.path.basename(os.path.dirname(p)), b)
    return names


def write(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb') as f:
        f.write(data)


def make_zip(folder, zip_path):
    root = os.path.dirname(folder)
    if os.path.exists(zip_path):
        os.remove(zip_path)
    n = 0
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as z:   # 파이썬 zipfile 은 비ASCII 이름에 UTF-8 플래그를 세운다
        for d, _, fs in sorted(os.walk(folder)):
            for f in sorted(fs):
                full = os.path.join(d, f)
                z.write(full, os.path.relpath(full, root))
                n += 1
    return n


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--repo', required=True); ap.add_argument('--name', required=True); ap.add_argument('--out', required=True)
    ap.add_argument('--base', default='HEAD'); ap.add_argument('--to', default='WORKTREE')
    ap.add_argument('--files', nargs='*'); ap.add_argument('--sql', nargs='*', default=[]); ap.add_argument('--evidence', nargs='*', default=[])
    ap.add_argument('--layout', choices=['wrb', 'scbk'], default='wrb')
    ap.add_argument('--eol', choices=['match', 'crlf', 'lf'], default='match')
    ap.add_argument('--date', default=datetime.date.today().strftime('%Y%m%d'))
    ap.add_argument('--no-zip', action='store_true'); ap.add_argument('--rezip', action='store_true'); ap.add_argument('--force', action='store_true')
    a = ap.parse_args()

    repo = os.path.abspath(a.repo)
    folder = os.path.join(os.path.abspath(a.out), a.name)
    zip_path = os.path.join(os.path.abspath(a.out), '%s_%s.zip' % (a.name, a.date))

    if a.rezip:
        if not os.path.isdir(folder):
            sys.exit('폴더 없음: ' + folder)
        print('zip 재생성: %s (%d개 파일)' % (zip_path, make_zip(folder, zip_path)))
        return

    if os.path.exists(folder):
        if not a.force:
            sys.exit('이미 있음: %s  (덮어쓰려면 --force, zip 만 다시 묶으려면 --rezip)' % folder)
        shutil.rmtree(folder)

    allc = changed_files(repo, a.base, a.to)
    if a.files:
        want = [os.path.relpath(os.path.abspath(os.path.join(repo, f)), repo) if not os.path.isabs(f) else os.path.relpath(f, repo) for f in a.files]
        want = [w.replace(os.sep, '/') for w in want]   # Windows: git 경로(/)와 맞춘다
        st = dict((p, s) for s, p in allc)
        missing = [w for w in want if w not in st]
        if missing:
            print('경고: base..to 에 변경이 없는 파일(그대로 포함): ' + ', '.join(missing), file=sys.stderr)
        files = [(st.get(w, '='), w) for w in want]
    else:
        files = allc
    if not files:
        sys.exit('변경 파일이 없습니다 (base=%s, to=%s)' % (a.base, a.to))

    paths = [p for _, p in files]
    flat = flat_names(paths)
    label = {'A': '신규', 'M': '수정', 'D': '삭제', 'R': '이동', '=': '변경없음'}
    listing = []
    for st, p in files:
        after = read_to(repo, a.to, p)
        before = match_eol(read_base(repo, a.base, p), after)
        before, after = force_eol(before, a.eol), force_eol(after, a.eol)
        if a.layout == 'wrb':
            if before is not None: write(os.path.join(folder, '원본', flat[p]), before)
            if after is not None:  write(os.path.join(folder, '수정본', flat[p]), after)
        else:
            if after is not None:  write(os.path.join(folder, '01_파일', p), after)
        listing.append('%s\t%s' % (label.get(st, st), p))

    # 미추적 신규 파일은 git diff 에 안 나오므로 /dev/null 기준 diff 를 덧붙인다 (스테이징된 신규 파일은 git diff 에 포함됨)
    untracked = set(git(repo, 'ls-files', '--others', '--exclude-standard').splitlines()) if a.to == 'WORKTREE' else set()
    tracked = [p for p in paths if p not in untracked]
    patch = b''
    if tracked:
        patch = git(repo, *(['diff', a.base] + ([] if a.to == 'WORKTREE' else [a.to]) + ['--'] + tracked), text=False)
    for p in paths:
        if p in untracked:
            patch += subprocess.run(['git', '-C', repo, 'diff', '--no-index', '--', '/dev/null', p], capture_output=True).stdout
    sha = git(repo, 'rev-parse', '--short=10', a.base).strip()
    branch = git(repo, 'rev-parse', '--abbrev-ref', 'HEAD').strip()
    today = datetime.date.today().isoformat()

    if a.layout == 'wrb':
        write(os.path.join(folder, 'patch', '01_%s.patch' % a.name), patch)
        write(os.path.join(folder, 'patch', '_filelist.txt'), ('\n'.join(listing) + '\n').encode('utf-8'))
        dbdir, evdir = 'DB', '증적'
    else:
        write(os.path.join(folder, 'patch.diff'), patch)
        dbdir, evdir = '02_DB', '증적'
    for srcs, sub in ((a.sql, dbdir), (a.evidence, evdir)):
        for s in srcs:
            os.makedirs(os.path.join(folder, sub), exist_ok=True)
            shutil.copy2(s, os.path.join(folder, sub, os.path.basename(s)))

    by_ext = {}
    for p in paths:
        by_ext.setdefault(os.path.splitext(p)[1].lstrip('.').lower() or '기타', []).append(os.path.splitext(flat[p])[0])
    filelist = '\n'.join(' %-5s : %s' % (k, ' / '.join(v)) for k, v in sorted(by_ext.items()))
    if a.sql: filelist += '\n sql   : ' + ' / '.join(os.path.basename(s) for s in a.sql)
    TODO = '(작성 필요)'
    if a.layout == 'wrb':
        readme = f"""{a.name} ({TODO}: 한 줄 제목) 소스 수정 산출물
==========================================================================

작성일 : {today}
기준 브랜치 : {branch} (기준 커밋 {sha})
원본 : git {a.base} 기준 ({'줄끝 CRLF 변환' if a.eol == 'crlf' else '줄끝은 수정본에 맞춤'})
수정본 : {'워킹트리 반영본' if a.to == 'WORKTREE' else a.to + ' 시점'}
태그 : {TODO}

1. 원인 요약
 - {TODO}

2. 수정 내용
 [A] {TODO}

3. 선행 DB 반영
 - {TODO} (없으면 "해당 없음")

4. 검증 ({today}, 환경 {TODO})
 - {TODO} — 실제로 수행한 것만, 미실행 항목은 사유와 함께

5. 주의 (파일 얽힘)
 - {TODO} (없으면 "해당 없음")

6. 파일 목록 ({len(paths)})
{filelist}
"""
        write(os.path.join(folder, 'README.txt'), readme.encode('utf-8'))
    else:
        rows = '\n'.join('| `%s` | %s | %s |' % (p, label.get(s, s), TODO) for s, p in files)
        readme = f"""# {a.name} — {TODO}: 한 줄 제목 ({today})

## 1. 배경
{TODO}

## 2. 변경 내용 (외부 개발 PC 저장소 기준, `patch.diff` — {branch} @ {sha})
| 파일 | 구분 | 변경 · 이유 |
|---|---|---|
{rows}

## 3. 내부망 수동 적용 절차
1. {TODO}

## 4. 개발DB 적용 기록
{TODO} (미적용이면 "미적용")

## 5. 남은 확인
- {TODO}
"""
        write(os.path.join(folder, 'README.md'), readme.encode('utf-8'))

    print('패키지 폴더: ' + folder)
    print('\n'.join('  ' + l for l in listing))
    print('README 의 "%s" 를 채운 뒤 %s' % (TODO, '끝.' if a.no_zip else '--rezip 으로 zip 을 다시 묶는다.'))
    if not a.no_zip:
        print('zip: %s (%d개 파일)' % (zip_path, make_zip(folder, zip_path)))


if __name__ == '__main__':
    main()
