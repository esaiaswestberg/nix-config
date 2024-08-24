{
	description = "Flake of Esaias Westberg";

	outputs = inputs@{ nixpkgs, ... }:
	let
		lib = nixpkgs.lib; # Needed for... Something.
		pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
		system = "x86_64-linux";

		# To remove duplication between configurations
		specialArgs = {
			inherit pkgs;
			inherit lib;
			inherit inputs;
		};

		commonModules = [
			inputs.home-manager.nixosModules.home-manager
			inputs.stylix.nixosModules.stylix
		];

	in {
		nixosConfigurations = {
			LOCA = lib.nixosSystem {
				inherit system;
				inherit specialArgs;
				modules = [ 
					./hosts/LOCA/configuration.nix
				] ++ commonModules;
			};

			TEMPLATE = lib.nixosSystem {
				inherit system;
				inherit specialArgs;
				modules = [ 
					./hosts/TEMPLATE/configuration.nix
				] ++ commonModules;
			};
		};

		homeManagerModules.default = import ./modules/home;
	};

	inputs = {
		nixpkgs.url = "nixpkgs/nixos-unstable";
		home-manager = {
			url = "github:nix-community/home-manager/master";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		# To configure KDE plasma using home-manager
		plasma-manager = {
			url = "github:nix-community/plasma-manager";
			inputs.nixpkgs.follows = "nixpkgs";
			inputs.home-manager.follows = "home-manager";
		};

		# Theme the entire system
		stylix.url = "github:danth/stylix";
	};
}
