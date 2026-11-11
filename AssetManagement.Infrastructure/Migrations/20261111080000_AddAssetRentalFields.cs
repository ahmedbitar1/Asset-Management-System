using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using AssetManagement.Infrastructure.Data;

#nullable disable

namespace AssetManagement.Infrastructure.Migrations
{
    /// <inheritdoc />
    [DbContext(typeof(ApplicationDbContext))]
    [Migration("20261111080000_AddAssetRentalFields")]
    public partial class AddAssetRentalFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "RentalValuation", table: "Assets", type: "decimal(18,2)", nullable: true);
            migrationBuilder.AddColumn<decimal>(
                name: "AnnualYield", table: "Assets", type: "decimal(18,2)", nullable: true);
            migrationBuilder.AddColumn<decimal>(
                name: "MarketValue", table: "Assets", type: "decimal(18,2)", nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(name: "RentalValuation", table: "Assets");
            migrationBuilder.DropColumn(name: "AnnualYield", table: "Assets");
            migrationBuilder.DropColumn(name: "MarketValue", table: "Assets");
        }
    }
}
