# 🏢 Asset Management System

## 📖 About

The **Asset Management System** is a comprehensive web-based application designed to manage real estate assets and track their workflow stages — from asset submission all the way to completing a sale or rental. The system provides an integrated environment for managing valuations, contracts, and multi-level approvals, with a precise role-based permission system for each job function.

Built with **ASP.NET Core MVC** following the **Repository Pattern** and **Clean Architecture** principles to ensure clear separation of concerns, maintainability, and scalability.

---

## 🔧 Key Features

### 🏗 Asset Management
- **Excel Import**: Upload multiple assets at once via a structured Excel file
- **Manual Entry**: Register a new asset with all its details manually
- **Search & Filter**: Search by name, code, or location; filter by stage or status
- **Full Details View**: Complete view of asset data, valuations, requests, and contracts
- **Print Report**: Print a comprehensive asset report with one click

### 🔄 Workflow — 10 Stages

| Stage | Name | Responsible Role |
|-------|------|-----------------|
| 1 | Asset Submission | Legal |
| 2 | Optional Stages | Marketing / Engineering / AdminAffairs |
| 3 | Valuation | Marketing + Finance + Legal (each enters their own) |
| 4 | Sale / Rental Request | Marketing |
| 5 | Final Approval | Board_High |
| 6 | Legal / Contract | Legal |
| 7 | Finance (Contract Review) | Finance |
| 8 | Upload Signed Contract | Legal |
| 9 | Treasury Collection | Treasury |
| 10 | Completed | — |

### 📊 Smart Valuation (Stage 3)
- Each role enters only their assigned valuation (Marketing / Finance / Expert)
- Asset stays in Stage 3 until all three valuations are submitted
- Once all three are complete → automatically advances to Stage 4

### 📋 Requests & Contracts
- **Rental Requests**: Record tenant data, monthly rent, duration, security deposit, and annual increase
- **Sale Requests**: Record buyer data, offered price, and payment method
- **Contract Generation**: Auto-generate Word contracts from pre-built templates
- **Signed Contract Upload**: Upload signed PDF or Word contract files
- **Request Printing**: Print a formatted request form with valuations and details

### 📈 Reports & Statistics
- Total assets by status (Active / Sold / Rented / Rejected / Pending)
- Asset distribution across stages with percentages
- Financial summary (total purchase value vs. current value)
- Export to Excel in the same format as the import sheet
- Latest 20 assets with full details

### 🖼 Image Management
- Upload multiple images per asset
- View images in a dedicated gallery

### 🔐 Role-Based Access Control

| Role | Permissions |
|------|-------------|
| **SuperAdmin** | Full access to everything |
| **Legal** | Add / Edit / Delete assets + Excel import + Create contracts + Upload signed contracts + Expert valuation |
| **Marketing** | Optional stages (marketing) + Rental & sale requests + Marketing valuation + Images |
| **Finance** | Finance valuation + Contract review (approve or reject) + View rental/sale requests |
| **Board_High** | Final approval (Stage 5) |
| **Engineering** | Optional stages (engineering) |
| **AdminAffairs** | Optional stages (admin affairs) |
| **Treasury** | Collection registration (Stage 9) |

---

## 💻 Technologies Used

### Backend
- **ASP.NET Core MVC** (.NET 8.0)
- **Entity Framework Core** for data access
- **SQL Server** for database management
- **EPPlus** for Excel import and export
- **DocX / Open XML** for Word contract generation

### Frontend
- **HTML5, CSS3**
- **Bootstrap 5 RTL** for responsive Arabic UI
- **Bootstrap Icons**
- **JavaScript / jQuery**
- **Cairo Font** (Google Fonts) for Arabic text rendering

### Architecture & Patterns
- **Repository Pattern** for data access abstraction
- **Service Layer** for business logic
- **Dependency Injection** for service management
- **Clean Architecture**: Domain / Application / Infrastructure / Web

---

## 🏗 Project Structure

```
AssetManagement/
├── AssetManagement.Domain/
│   ├── Entities/          # Core models (Asset, Contract, StageHistory...)
│   ├── Enums/             # Enumerations (AssetStatus, AssetType, EvaluationType...)
│   └── Interfaces/        # Repository interfaces
│
├── AssetManagement.Application/
│   ├── ViewModels/        # View models (DashboardViewModel, ValuationViewModel...)
│   ├── Services/          # Business logic (WorkflowService, ExcelImportService...)
│   └── Interfaces/        # Service interfaces
│
├── AssetManagement.Infrastructure/
│   ├── Data/              # DbContext and database configuration
│   ├── Repository/        # Repository implementations
│   └── Migrations/        # EF Core database migrations
│
└── AssetManagement.Web/
    ├── Controllers/       # MVC controllers
    ├── Views/             # Razor views (Arabic UI)
    ├── Helpers/           # Utility helpers
    └── wwwroot/           # CSS, JS, images, contract templates
```

---

## ⚙️ Setup & Installation

### Prerequisites
- **.NET 8.0 SDK**
- **SQL Server** 2017 or later
- **Visual Studio 2022** or **VS Code**
- **Git**

### Installation Steps

**1. Clone the repository**
```bash
git clone https://github.com/ahmedbitar1/Asset-Management-System.git
cd Asset-Management-System
```

**2. Configure the database**

Create `appsettings.json` inside the `AssetManagement.Web` folder:
```json
{
  "ConnectionStrings": {
    "Default": "Server=YOUR_SERVER;Database=AssetManagementDB;User Id=YOUR_USER;Password=YOUR_PASSWORD;TrustServerCertificate=True;"
  }
}
```

**3. Apply database migrations**
```bash
cd AssetManagement.Infrastructure
dotnet ef database update
```

**4. Build the project**
```bash
cd ..
dotnet build
```

**5. Run the application**
```bash
dotnet run --project AssetManagement.Web
```

**6. Open in browser**
```
https://localhost:5001
```

---

## 👤 Default Login Credentials

| Username | Password | Role |
|----------|----------|------|
| admin | 1234 | SuperAdmin |
| legal1 | Test@1234 | Legal |
| marketing1 | Test@1234 | Marketing |
| finance1 | Test@1234 | Finance |
| board_high1 | Test@1234 | Board_High |
| treasury1 | Test@1234 | Treasury |
| engineering1 | Test@1234 | Engineering |
| adminaffairs1 | Test@1234 | AdminAffairs |

---

## 📝 Excel Import Format

The Excel file must contain the following columns in order:

| Column | Data |
|--------|------|
| A | City / Governorate |
| B | District / Division |
| C | Asset Name *(required)* |
| D | Description |
| E | Property Type |
| F | Land Area (m²) |
| G | Building Area (m²) |
| H | Deed Type |
| I | Owner Company |
| J | Occupancy Status |
| K | Notes |
| L | Previous Offers |

> Row 1 is the header row and is automatically skipped.

---

## 🔌 Detailed Workflow

```
[Legal] Submit asset (manual or Excel import)
    ↓
[Marketing / Engineering / AdminAffairs] Optional stages
    ↓
[Marketing + Finance + Legal] Triple valuation (each enters their own)
    ↓  (auto-advances when all three are complete)
[Marketing] Create rental or sale request
    ↓
[Board_High] Final approval or rejection
    ↓
[Legal] Create contract
    ↓
[Finance] Review contract + view rental/sale requests
    ↓
[Legal] Upload signed contract
    ↓
[Treasury] Register collection
    ↓
✅ Completed (Sold / Rented)
```

---

## 🛠 Troubleshooting

**Database connection error**
- Verify the connection string in `appsettings.json`
- Make sure SQL Server is running

**Access Denied**
- Verify the user has the correct role assigned
- Check `StageDefinition.cs` for role assignments per stage

**Excel import fails**
- Make sure the file has a `.xlsx` extension
- Make sure column C (Asset Name) is not empty in any data row

---

## 📬 Contact

**Developer**: Ahmed Essam
**Email**: ahmedesamo778@gmail.com
**GitHub**: [ahmedbitar1](https://github.com/ahmedbitar1)

---

## 📄 License

This project is proprietary software developed for internal use.
