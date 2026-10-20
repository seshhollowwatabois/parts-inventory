# მარაგი

ქართული ვებაპლიკაცია ავტონაწილების მარაგის, გაყიდვებისა და მთლიანი მოგების აღსარიცხად. იყენებს GitHub Pages-ს ჰოსტინგისთვის და Supabase-ს ავტორიზაციისა და მონაცემთა ბაზისთვის.

## ფაილები
- `index.html` — ვებსაიტი.
- `supabase-setup.sql` — ცხრილები, უსაფრთხოების პოლიტიკები (RLS) და გაყიდვის ტრანზაქცია.

## დაყენება
1. შექმენით Supabase პროექტი: https://supabase.com/dashboard
2. Supabase-ში გახსენით **SQL Editor → New query**, ჩასვით `supabase-setup.sql`-ის შიგთავსი და გაუშვით.
3. გახსენით **Authentication → Providers** და ჩართეთ Email/Password.
4. შექმენით თქვენი მომხმარებელი აპის **ანგარიშის შექმნა** ღილაკით ან Supabase → Authentication → Users-ში. მომხმარებლის შექმნის შემდეგ დააკოპირეთ მისი UUID.
5. SQL Editor-ში გაუშვით შემდეგი ბრძანება თქვენი UUID-ითა და ელფოსტით:
   ```sql
   insert into public.team_members(user_id,email,role,active)
   values ('YOUR_AUTH_USER_UUID'::uuid,'your-email@example.com','owner',true);
   ```
6. ამ GitHub repository-ში `index.html` და `supabase-setup.sql` უნდა იყოს root საქაღალდეში.
7. GitHub-ზე გახსენით **Settings → Pages → Build and deployment**, აირჩიეთ **Deploy from a branch**, branch `main`, folder `/(root)`, შემდეგ **Save**.
8. გახსენით გამოქვეყნებული საიტი და პირველ ეკრანზე ჩაწერეთ Supabase Project URL და **publishable key** (ან legacy anon key). არასოდეს გამოიყენოთ `service_role` ან secret key ბრაუზერში.
9. თანამშრომლისთვის შექმენით მომხმარებელი Supabase → Authentication → Users-ში, შემდეგ აპის **თანამშრომლები** ჩანართში მიუთითეთ მისი User ID, ელფოსტა და როლი.

## ფუნქციები
- ავტორიზაცია ელფოსტითა და პაროლით
- ნაწილების დამატება, ძიება და მარაგის შევსება
- გაყიდვის ჩაწერა მარაგის ავტომატური შემცირებით
- გაყიდვების ისტორია, შემოსავალი და მთლიანი მოგება
- CSV ექსპორტი და თანამშრომლების წვდომის მართვა

## უსაფრთხოება
GitHub Pages-ის წყარო საჯაროა. პირადი მონაცემები ინახება Supabase-ში და დაცულია Auth + Row Level Security-ით. მხოლოდ აქტიურ `team_members` წევრებს შეუძლიათ მარაგისა და გაყიდვების ნახვა. საწყისი დაყენების შემდეგ, თუ ღია რეგისტრაცია არ გჭირდებათ, გამორთეთ public sign-ups Supabase Authentication-ის პარამეტრებში. publishable key ბრაუზერში ხილული იქნება — უსაფრთხოება უზრუნველყოფილია RLS პოლიტიკებით და არა გასაღების დამალვით.
