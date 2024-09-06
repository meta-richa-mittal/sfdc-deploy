public class BRPVehicleResponseWrapper {

    public ShowVehicleSpecifications ShowVehicleSpecifications;
    
    public class ShowVehicleSpecifications {
        public ShowVehicleSpecificationsDataArea ShowVehicleSpecificationsDataArea;
    }
    
    public class ShowVehicleSpecificationsDataArea {
        public VehicleSpecifications VehicleSpecifications;
    }
    
    public class VehicleSpecifications {
        public VehicleSpecificationsLine VehicleSpecificationsLine;
    }
    
    public class VehicleSpecificationsLine {
        public Vehicle Vehicle;
    }
    
    public class Vehicle {
        public String VehicleDescription;
        public String ModelGroup;
        public String ManufacturerName;
        public String VehicleID;
        public Engine Engine;
        public String ModelDescription;
        public String ModelYear;
        public String Model;
        public String Make = 'BRP';
        public BRPUnitSpecificationsService.UnitSpecificationResWrapper BRPUnitSpecifications;

        public Vehicle( BRPUnitSpecificationsService.UnitSpecificationResWrapper responseObj) {
            this.Make = responseObj.manufacturer_name;
            this.Model = responseObj.model_number;
            this.ModelDescription = responseObj.model_name;
            this.ModelYear = String.valueOf(responseObj.model_year);
            this.Engine = new Engine(String.valueOf(responseObj.no_of_cylinders));
        }
    }
    
    public class Engine {
        public String DisplacementMeasure;
        public String NumberOfEngineCylindersNumeric;

        public Engine( String numberofEngineCylinders) {
            this.NumberOfEngineCylindersNumeric = numberofEngineCylinders;
        }
    }
}