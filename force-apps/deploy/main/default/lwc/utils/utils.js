import Toast from 'lightning/toast';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getFieldDisplayValue, getFieldValue } from 'lightning/uiRecordApi';

export default class Utils {
	static etErrorsToString(errors) {
		// https://developer.salesforce.com/docs/component-library/documentation/en/lwc/data_error
		// Make array if only one.
		if (!Array.isArray(errors)) {
			errors = [errors];
		}

		// Remove null/undefined items
		errors = errors.filter((error) => !!error);

		// Extract an error message
		errors = errors.map((error) => {
			// UI API read errors
			if (Array.isArray(error.body)) {
				return error.body.map((e) => e.message);
			}

			// UI API DML, Apex and network errors
			if (error.body) {
				if (typeof error.body.message === 'string') {
					return error.body.message;
					// eslint-disable-next-line no-else-return
				} else {
					try {
						let errorMessage = JSON.stringify(error.body, null, 2);
						if (typeof errorMessage === 'string') {
							return errorMessage;
						}
						// if (
						// 	error.body.fieldErrors ||
						// 	(error.body.pageErrors && error.body.pageErrors.length > 0) ||
						// 	error.body.index ||
						// 	(error.body.duplicateResults && error.body.duplicateResults.length > 0)
						// ) {
						// 	let errorMessage = "";
						// 	if (error.body.fieldErrors) {
						// 		if (errorMessage.length > 0) {
						// 			errorMessage += " ";
						// 		}
						// 		errorMessage += "Field errors: ";
						// 		for (const [key, value] of Object.entries(error.body.fieldErrors)) {
						// 			errorMessage += `Field: ${key}. Error(s): `;
						// 			value.forEach((fieldError, index) => {
						// 				if (index > 0) {
						// 					errorMessage += ", ";
						// 				}
						// 				errorMessage += JSON.stringify(fieldError);
						// 			});
						// 		}
						// 	}
						// 	if (error.body.pageErrors && error.body.pageErrors.length > 0) {
						// 		if (errorMessage.length > 0) {
						// 			errorMessage += " ";
						// 		}
						// 		errorMessage += "Page errors: ";
						// 		error.body.pageErrors.forEach((pageError, index) => {
						// 			if (index > 0) {
						// 				errorMessage += ", ";
						// 			}
						// 			errorMessage += JSON.stringify(pageError);
						// 		});
						// 	}
						// 	if (error.body.index) {
						// 		if (errorMessage.length > 0) {
						// 			errorMessage += " ";
						// 		}
						// 		errorMessage += `Index: ${error.body.index}`;
						// 	}
						// 	if (error.body.duplicateResults && error.body.duplicateResults.length > 0) {
						// 		if (errorMessage.length > 0) {
						// 			errorMessage += " ";
						// 		}
						// 		errorMessage += "Duplicate Results: ";
						// 		error.body.duplicateResults.forEach((duplicateResult, index) => {
						// 			if (index > 0) {
						// 				errorMessage += ", ";
						// 			}
						// 			errorMessage += JSON.stringify(duplicateResult);
						// 		});
						// 	}
						// 	return errorMessage;
						// }
					} catch (ex) {
						// Ignore conversion errors
					}
				}
			}

			// JS errors
			else if (typeof error.message === 'string') {
				return error.message;
			}

			// Unknown error shape so try HTTP status text
			return error.statusText;
		});

		// Flatten
		errors = errors.reduce((prev, curr) => prev.concat(curr), []);

		// Remove empty strings
		errors = errors.filter((message) => !!message);

		// Make it a string
		errors = errors.join(', ');

		// Replace curly brackets with parenthesis
		errors = errors.replace(/{/g, '(');
		errors = errors.replace(/}/g, ')');

		return errors;
	}

	static msgVariants = {
		error: 'error',
		warning: 'warning',
		success: 'success',
		info: 'info'
	};

	static msgModes = {
		sticky: 'sticky', // remains visible until you click the close button
		pester: 'pester', // remains visible for 3 seconds and disappears automatically. No close button is provided
		dismissible: 'dismissible' // Remains visible until you click the close button or 3 seconds has elapsed, whichever comes first
	};

	static STATES = {
		// WARNING: These constants are also set in Apex independently
		// WARNING: These constants are also set in Apex independently
		// WARNING: These constants are also set in Apex independently
		// WARNING: These constants are also set in Apex independently
		// WARNING: These constants are also set in Apex independently
		START: () => {
			return '00-START';
		},
		WORKING: () => {
			return '01-WORKING';
		},
		LATER: () => {
			return '02-LATER';
		},
		DONE: () => {
			return '03-DONE';
		},
		ABSENT: () => {
			return '04-ABSENT';
		},
		COURSE_ALL: () => {
			return 'ALL';
		},
		EXERCISE_SURVEY: () => {
			return 'Please complete the survey';
		},
		EXERCISE_ATTENDANCE: () => {
			return 'Student attendance';
		}
	};

	static questionTypes = {
		TEXT: 'Text',
		BOOLEAN: 'Boolean',
		SELECT_ONE: 'Select One',
		SELECT_TWO: 'Select Two',
		SELECT_THREE: 'Select Three',
		NOT_GRADED: 'Not-Graded'
	};

	static showNotification(cmp, { title = '', message = '', variant = 'success', mode = 'dismissible' }) {
		const isSite = window.location.host.endsWith('.my.site.com');
		if (isSite) {
			Toast.show(
				{
					label: title,
					message,
					mode,
					variant
				},
				cmp
			);
		} else {
			cmp.dispatchEvent(
				new ShowToastEvent({
					title,
					message,
					variant,
					mode
				})
			);
		}
	}

	static reportError(cmp, { error, title = 'An Error Has Occurred' }) {
		let msg;
		console.error(error);
		if (typeof error === 'string') {
			msg = error;
		} else {
			msg = this.etErrorsToString(error);
		}
		console.error(msg);
		debugger;
		if (cmp) {
			this.showNotification(cmp, { title, message: msg, variant: 'error', mode: 'sticky' });
		} else {
			throw new Error(msg);
		}
	}

	static calculateDuration({ startAt, endAt }) {
		const toString = (withLeadingZeroes, params) => {
			let { factor, rounding } = params;
			let { days, hours, minutes, seconds, milliseconds } = params.diff;

			// let output = `${days > 0 ? days + "d " : ""}${("00" + hours).slice(-2)}h ${("00" + minutes).slice(-2)}m ${("00" + seconds).slice(-2)}s`;
			let output = '';

			let strDays = '';
			let strHours = '';
			let strMinutes = '';
			let strSeconds = '';
			let strMilliseconds = '';
			if (withLeadingZeroes) {
				if (days > 0) {
					strDays = `${days} d`;
				}
				if (hours > 0 || days > 0) {
					strHours = `${('00' + hours).slice(-2)} h`;
				}
				strMinutes = `${('00' + minutes).slice(-2)} m`;
				strSeconds = `${('00' + seconds).slice(-2)} s`;
				strMilliseconds = `${('000' + milliseconds).slice(-3)} ms`;
			} else {
				if (days > 0) {
					strDays = `${days} d`;
				}
				if (hours > 0 || days > 0) {
					strHours = `${hours} h`;
				}
				strMinutes = `${minutes} m`;
				strSeconds = `${seconds} s`;
				strMilliseconds = `${milliseconds} ms`;
			}
			switch (rounding) {
				case 'MILLIS': {
					output = `${strDays} ${strHours} ${strMinutes} ${strSeconds} ${strMilliseconds}`;
					break;
				}
				case 'SEC': {
					output = `${strDays} ${strHours} ${strMinutes} ${strSeconds}`;
					break;
				}
				case 'MIN': {
					output = `${strDays} ${strHours} ${strMinutes}`;
					break;
				}
				case 'HOUR': {
					output = `${strDays} ${strHours}`;
					break;
				}
				case 'DAY': {
					output = `${strDays}`;
					break;
				}
				default:
					break;
			}

			if (days + hours + minutes + seconds > 0 && factor < 0) {
				output = `- ${output}`;
			}
			return output.trim();
		};

		const parse = ({ start, end, rounding }) => {
			let output = {
				total: 0,
				diff: {},
				rounding,
				values: {},
				factor: start <= end ? 1 : -1
			};

			switch (rounding) {
				case 'MILLIS': {
					rounding = 1 / 1000;
					break;
				}
				case 'SEC': {
					rounding = 1;
					break;
				}
				case 'MIN': {
					rounding = 1 * 60;
					break;
				}
				case 'HOUR': {
					rounding = 1 * 60 * 60;
					break;
				}
				case 'DAY': {
					rounding = 1 * 60 * 60 * 24;
					break;
				}
				default:
					break;
			}

			// Substracting 2 dates returns number of milliseconds
			let delta = Math.abs(start - end) / 1000;

			// Apply rounding
			delta = Math.round(delta / rounding) * rounding;
			output.total = delta;

			// calculate (and subtract) whole days
			output.diff.days = Math.floor(delta / 86400);
			delta -= output.diff.days * 86400;

			// calculate (and subtract) whole hours
			output.diff.hours = Math.floor(delta / 3600) % 24;
			delta -= output.diff.hours * 3600;

			// calculate (and subtract) whole minutes
			output.diff.minutes = Math.floor(delta / 60) % 60;
			delta -= output.diff.minutes * 60;

			// calculate whole seconds and subtract for milliseconds
			output.diff.seconds = Math.floor(delta);
			output.diff.milliseconds = Math.round((delta - Math.floor(delta)) * 1000);

			// Values
			output.values.seconds = output.total;
			output.values.minutes = output.values.seconds / 60;
			output.values.hours = output.values.minutes / 60;
			output.values.days = output.values.hours / 24;

			// Make string
			output.toString = function (withLeadingZeroes = false) {
				let string = toString(withLeadingZeroes, this);
				return string;
			};

			return output;
		};

		let output = null;
		startAt = new Date(startAt);
		endAt = new Date(endAt);
		if (!isNaN(startAt.getTime()) && !isNaN(endAt.getTime())) {
			output = {
				milliseconds: {},
				seconds: {},
				minutes: {},
				hours: {},
				days: {}
			};

			output.milliseconds = parse({ start: startAt, end: endAt, rounding: 'MILLIS' });
			output.seconds = parse({ start: startAt, end: endAt, rounding: 'SEC' });
			output.minutes = parse({ start: startAt, end: endAt, rounding: 'MIN' });
			output.hours = parse({ start: startAt, end: endAt, rounding: 'HOUR' });
			output.days = parse({ start: startAt, end: endAt, rounding: 'DAY' });
		}

		return output;
	}

	static setCookie({ key, value }) {
		document.cookie = `${key}=${value}`;
	}

	static getCookie({ key }) {
		let output = null;

		document.cookie.split(';').find((cookie) => {
			let isFound = cookie.trim().startsWith(key + '=');
			if (isFound) {
				output = cookie.split('=')[1];
			}
			return isFound;
		});
		return output;
	}

	static deleteCookie({ key }) {
		document.cookie = `${key}=; expires=Thu, 01 Jan 1970 00:00:00 UTC;`;
	}

	static getEmoji({ status }) {
		let output = '';
		switch (status) {
			case Utils.STATES.DONE(): {
				output = '✅';
				break;
			}
			case Utils.STATES.WORKING(): {
				output = '👩‍💻';
				break;
			}
			case Utils.STATES.LATER(): {
				output = '🕒';
				break;
			}
			case Utils.STATES.START(): {
				output = '⚒️';
				break;
			}
			case Utils.STATES.ABSENT(): {
				output = '🚫';
				break;
			}
			default:
				output = '❓';
				break;
		}
		// Utils.logger.log(`${status} => ${output}`);
		return output;
	}

	static logger = {
		log: (...params) => {
			console.log(Utils.logger._source(), ...params);
		},
		error: (...params) => {
			console.error(Utils.logger._source(), ...params);
		},
		_source: () => {
			let source;
			const stack = Error().stack.split('\n');
			stack.shift();

			let caller = stack.find((line) => !line.includes('/utils.js:')).trim();
			caller = caller.substring(caller.lastIndexOf('/') + 1);
			caller = caller.substring(0, caller.length - 1);

			source = `(${new Date().toJSON()} *** ${caller})`;

			return source;
		}
	};

	static async validateAttendeeRegistration({ apexManager, deliveryId, attendeeId }) {
		let output = null;
		if (deliveryId == null || attendeeId == null) {
			// Should I clear these?
			// Utils.deleteCookie({ key: "deliveryId" });
			// Utils.deleteCookie({ key: "attendeeId" });
		} else {
			output = await apexManager.doValidateAttendeeRegistration({ deliveryId, attendeeId });
			if (output) {
				Utils.setCookie({ key: 'deliveryId', value: output.delivery.Id });
				Utils.setCookie({ key: 'attendeeId', value: output.attendee.Id });
			} else {
				Utils.deleteCookie({ key: 'deliveryId' });
				Utils.deleteCookie({ key: 'attendeeId' });
			}
		}
		return output;
	}

	static findRecord({ list, Id }) {
		let output = list.filter((item) => item.Id === Id);
		if (output.length === 1) {
			output = output[0];
		} else {
			output = null;
		}
		return output;
	}

	static getField(record, field) {
		return getFieldDisplayValue(record, field) ? getFieldDisplayValue(record, field) : getFieldValue(record, field);
	}

	static namespace = ''; // 'thstudentengage__';

	static removeNamespace({ strData }) {
		// I am glad, I decided early on to have one central location to access the data and connect to Apex. Otherwise this change would of have been crazy. It touches the entire code!
		return strData.replaceAll(Utils.namespace, '');
	}

	static addNamespace({ objData }) {
		const output = {};
		Object.keys(objData).forEach((key) => {
			const newKey = key.endsWith('__c') ? `${Utils.namespace}${key}` : key;
			output[newKey] = objData[key];
		});
		return output;
	}
}
