from supabase import create_client, Client
import pandas as pd
import getpass
import sys

# === Supabase credentials ===
SUPABASE_URL = 'https://sxmqgbcjgppvidlaqdqd.supabase.co'
SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN4bXFnYmNqZ3BwdmlkbGFxZHFkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk4MDQ4NTEsImV4cCI6MjA2NTM4MDg1MX0.QOTyUYRJZ96Uz3rRN4TQ_xS3B7XpUCXA7moCNL-Qj4Y'

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def login_as_dosen():
    print("=== LOGIN SEBAGAI DOSEN ===")
    email = input("Email: ")
    password = getpass.getpass("Password: ")

    try:
        # Proses login Supabase
        auth_response = supabase.auth.sign_in_with_password({
            "email": email,
            "password": password
        })
        user_id = auth_response.user.id

        # Cek status di tabel profiles
        profile = supabase.table("profiles").select("status").eq("id", user_id).single().execute()
        status = profile.data.get("status", "").strip().lower()
        if status != "dosen":
            print(f"⛔ Akses ditolak: kamu bukan dosen (status = '{status}')")
            sys.exit()

        print(f"✅ Login berhasil sebagai dosen: {email}")
        return user_id

    except Exception as e:
        print(f"❌ Login gagal: {e}")
        sys.exit()

def export_answers(kode_kuis):
    try:
        # Cari kuis dari kode_kuis
        quiz_data = supabase.table("quizzes").select("id,title").eq("kode_kuis", kode_kuis).execute()
        if not quiz_data.data:
            print("❌ Kode kuis tidak ditemukan.")
            return

        quiz_id = quiz_data.data[0]["id"]
        quiz_title = quiz_data.data[0]["title"]
        print(f"📘 Kuis ditemukan: {quiz_title} (ID: {quiz_id})")

        # Coba beberapa kemungkinan nama tabel attempt
        attempt_table_names = ["quiz_attempts", "attempts", "attempt"]
        attempts = None
        
        for table_name in attempt_table_names:
            try:
                attempts = supabase.table(table_name).select("id,user_id").eq("quiz_id", quiz_id).execute()
                print(f"✔ Menggunakan tabel: {table_name}")
                break
            except:
                continue

        if not attempts:
            print("❌ Tidak dapat menemukan tabel attempt. Coba nama tabel berikut:")
            print("- quiz_attempts")
            print("- attempts") 
            print("- attempt")
            return

        if not attempts.data:
            print("❌ Tidak ada attempt ditemukan untuk kuis ini.")
            return

        attempt_ids = [a["id"] for a in attempts.data]
        user_ids = [a["user_id"] for a in attempts.data]

        # Ambil data profil pengisi quiz
        profiles = supabase.table("profiles").select("id,full_name,nim_nip,status").in_("id", user_ids).execute()
        profile_map = {p["id"]: p for p in profiles.data}

        # Ambil jawaban dari tabel answers
        answers = supabase.table("answers").select("*").in_("attempt_id", attempt_ids).execute()
        if not answers.data:
            print("❌ Tidak ada jawaban ditemukan.")
            return

        # Gabungkan data dengan informasi profil
        rows = []
        for ans in answers.data:
            attempt_id = ans["attempt_id"]
            user_id = next((a["user_id"] for a in attempts.data if a["id"] == attempt_id), None)
            profile = profile_map.get(user_id, {"full_name": "Unknown", "nim_nip": "N/A", "status": "N/A"})

            rows.append({
                "Nama Pengisi": profile["full_name"],
                "NIM/NIP": profile["nim_nip"],
                "Status": profile["status"],
                "Attempt ID": attempt_id,
                "Question ID": ans.get("question_id"),
                "Jawaban Teks": ans.get("answer_text"),
                "Jawaban Gambar": ans.get("answer_image_url"),
                "Skor": ans.get("score"),
            })

        # Simpan ke Excel
        df = pd.DataFrame(rows)
        
        # Urutkan berdasarkan nama pengisi
        df.sort_values(by=["Nama Pengisi", "Attempt ID"], inplace=True)
        
        filename = f"jawaban_{kode_kuis}.xlsx"
        df.to_excel(filename, index=False)
        print(f"✅ File Excel berhasil dibuat: {filename}")
        print("ℹ Data yang disertakan: Nama, NIM/NIP, Status, dan jawaban quiz")

    except Exception as e:
        print(f"❌ Error saat export answers: {e}")

if __name__ == "__main__":
    user_id = login_as_dosen()
    kode_kuis = input("Masukkan KODE_KUIS: ").strip()
    export_answers(kode_kuis)