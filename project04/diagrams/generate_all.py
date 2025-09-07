#!/usr/bin/env python3
"""
Project 04 - 아키텍처 다이어그램 생성 스크립트
간결하고 명확한 아키텍처 다이어그램들 생성
"""

import subprocess
import sys
import os
from pathlib import Path

def run_diagram_script(script_name):
    """개별 다이어그램 스크립트 실행"""
    try:
        print(f"🔄 {script_name} 생성 중...")
        result = subprocess.run([sys.executable, script_name], 
                              capture_output=True, text=True, check=True)
        print(f"✅ {script_name} 생성 완료")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ {script_name} 생성 실패: {e}")
        print(f"   stdout: {e.stdout}")
        print(f"   stderr: {e.stderr}")
        return False
    except Exception as e:
        print(f"❌ {script_name} 실행 중 오류: {e}")
        return False

def main():
    """메인 실행 함수"""
    print("🚀 Project 04 - 아키텍처 다이어그램 생성 시작")
    print("=" * 60)
    
    # 현재 디렉토리 확인
    current_dir = Path(__file__).parent
    os.chdir(current_dir)
    
    # 생성할 다이어그램 스크립트 목록
    diagram_scripts = [
        "main_architecture.py",
        "security_architecture.py", 
        "monitoring_architecture.py",
        "istio_ambient_architecture.py",
        "istio_sidecar_architecture.py"
    ]
    
    # 각 스크립트 실행
    success_count = 0
    total_count = len(diagram_scripts)
    
    for script in diagram_scripts:
        if Path(script).exists():
            if run_diagram_script(script):
                success_count += 1
        else:
            print(f"⚠️  {script} 파일을 찾을 수 없습니다.")
    
    # 결과 요약
    print("=" * 60)
    print(f"📊 생성 결과: {success_count}/{total_count} 성공")
    
    if success_count == total_count:
        print("🎉 모든 아키텍처 다이어그램이 성공적으로 생성되었습니다!")
        print("\n📁 생성된 파일들:")
        for script in diagram_scripts:
            base_name = script.replace('.py', '')
            png_file = f"{base_name}.png"
            if Path(png_file).exists():
                print(f"   - {png_file}")
        print("\n💡 이제 간결하고 명확한 아키텍처를 확인할 수 있습니다!")
    else:
        print("⚠️  일부 다이어그램 생성에 실패했습니다.")
        sys.exit(1)

if __name__ == "__main__":
    main()
